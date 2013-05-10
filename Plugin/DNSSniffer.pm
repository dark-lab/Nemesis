package Plugin::DNSSniffer;
use MooseX::Declare;

use Nemesis::Inject;

# moduli per la gestione dei pacchetti
use Net::Frame;
use Net::Frame::Simple;
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);

use Net::DNS::Packet;
use Data::Dumper;

use NetPacket::UDP;
use NetPacket::IP;

class Plugin::DNSSniffer {

    our $VERSION = '0.1a';
    our $AUTHOR  = "luca9010";
    our $MODULE  = "DNSSniffer plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(start stop);

    nemesis_module;

    has 'Sniffer' => (
        is => 'rw'
    );

    method start() {

      if($self->Init->checkroot()){
        $self->Init->getIO()->print_alert("You need root permission to do this; otherwise you wouldn't see anything");
      }
          my $Process=$self->Init->getModuleLoader->loadmodule("Process");
          my $Monitor=$self->Init->getModuleLoader->loadmodule("Monitor");

            $Process->set(
                type=> "thread",
                instance=>$Monitor
                );
            $Process->start();
            $self->Sniffer($Process);
    }

    method clear(){
      $self->stop();
    }

    method stop(){
        $self->Sniffer()->destroy() if($self->Sniffer);
    }


    method event_udp(@Info){
        my $IO = $Init->io;
        #$Init->io->info(__PACKAGE__." Received a UDP package");
        my $ipv4;
        my $udp;
        #my $dns;
        foreach my $Packet (@Info){
            if( $Packet->isa("NetPacket::IP") ) {
                my $InfoIP=Net::IP->new($Packet->{src_ip});
                my $SrcType=$InfoIP->iptype;
                $InfoIP=Net::IP->new($Packet->{dest_ip});
                my $DstType=$InfoIP->iptype;                  
                ######$self->Init->getIO()->print_info("IP packet: ".$Packet->{src_ip}."(".$SrcType.") -> ".$Packet->{dest_ip}."(".$DstType.")");

                # Build IPv4 header
                #$ip = Net::Packet::IPv4->new(dst => $Packet->{src_ip}, src => "192.168.1.19");

                $ipv4   = Net::Frame::Layer::IPv4->new(
                 #src => "192.168.1.4",
                 src => $Packet->{dest_ip} ,
                 dst => $Packet->{src_ip},
                );
 
            } elsif( $Packet->isa("NetPacket::UDP") ) {
                if($Packet->{dest_port} eq "53"){

                    if ($Packet->{len}) {
                        my $payload2 = $Packet->{data};
                        my $test = Net::DNS::Packet->new(\$payload2);
                        if ($test) {
                            my @answer = $test->question;
                            ######$self->Init->getIO()->print_info("ANSWER: ". $test->print);
                        } else {
                            $self->Init->getIO()->print_info( "no Net::DNS::Packet \n");}
                        
                    my @question = $test->question;
                    my $headerId = $test->header->id;

                    $self->Init->getIO()->print_info("UDP packet: ".$Packet->{src_port}." -> ".$Packet->{dest_port});
                    foreach my $q (@question) {
                        $self->Init->getIO()->print_info($q->string);
                    }
                    $self->Init->getIO()->print_info("ID: ". $headerId);

                    }
                    # Build UDP header
                    #$udp = Net::Packet::UDP->new(dst => $Packet->{src_port}, src => $Packet->{dest_port});
                    $udp = Net::Frame::Layer::UDP->new(
                        src      => $Packet->{dest_port},
                        dst      => $Packet->{src_port},
                    );

                    #build an DNS header
                    # use Net::Frame::Layer::DNS qw(:consts);
 
                    # $dns = Net::Frame::Layer::DNS->new(
                    #                                    id      => # ci devo mettere l'id della richiesta dns della vittima,
                    #                                    qr      => NF_DNS_QR_RESPONSE, # messaggio dns di risposta (corrisposnde a valore booleano 1)
                    #                                    opcode  => NF_DNS_OPCODE_QUERY, # deve avere lo stesso valore dello stesso campo presente nel pacchetto dns di richiesta
                    #                                    flags   => NF_DNS_FLAGS_AA,
                    #                                    rcode   => NF_DNS_RCODE_NOERROR, # deve essere a NOERROR o a zero per indicare che non ci sono stati errori nella richiesta
                    #                                    qdCount => 1, # n° di entry nella sezione quetion
                    #                                    anCount => 0, # n° di entry nella sezione response
                    #                                    nsCount => 0, # n° of name server resource records in the authority records section.
                    #                                    arCount => 0, # n° of resource records in the additional records section.
                    #                                     );

                    # Riassembla il frame

                    # my $frame = Net::Packet::Frame->new(l3 => $ip, l4 => $udp);
                    # $frame->send;
                    my $packet = Net::Frame::Simple->new(
                                                            layers => [$ipv4, $udp]
                                                        ); 
                    ######$self->Init->getIO()->print_info($packet->print . "\n"); 
                    $packet->pack;
                    # $packet->send;  # ?? come si invia ??              
                }
            }else {
                #  $self->Init->io()->debug_dumper(\$Packet);
            }
        }
    }

}
1;

