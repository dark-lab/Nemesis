package  Resources::Network::DHCPD;

# http://cpansearch.perl.org/src/DJZORT/Net-DHCP-0.693/examples/dhcpd.pl
use Nemesis::BaseRes -base;

use Sys::Hostname;
use Socket;
use Net::DHCP::Packet;
use Net::DHCP::Constants;
use POSIX qw(setsid strftime);

use IO::Socket::INET;

has 'iface';

# sample logger


$SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { threads->exit };

# trap or ignore $SIG{PIPE}


# Daemon behaviour
# ignore any PIPE signal: standard behaviour is to quit process
$SIG{PIPE} = 'IGNORE';

# accept only from selected VENDOR classes (avoids messing existing networks)
my $VENDOR_ACCEPTED = "foo|bar";

# broadcast address
my $bcastaddr = sockaddr_in( "68", INADDR_BROADCAST );

# get a flag to force daemon to stop
my $time_to_die = 0;

# generic signal handler to cause daemon to stop
sub run() {
    my $self = shift;

    # open listening socket
    my $sock_in = IO::Socket::INET->new(
        LocalPort => 67,
        LocalAddr => "127.0.0.1",
        Proto     => 'udp'
    ) || die "Socket creation error: $@\n";

    $self->Init->io->info(
        "Initialization complete, listening for now connections");

    # main loop
    #
    # process incoming packets
    my $transaction = 0;    # report transaction number

    while (1) {
        my $buf = undef;
        my $fromaddr;       # address & port from which packet was received
        my $dhcpreq;

        eval {              # catch fatal errors
            $self->Init->io->info("Waiting for incoming packet");

            # receive packet
            $fromaddr = $sock_in->recv( $buf, 4096 )
                || $self->Init->io->debug("recv:$!");
            next if ($!);    # continue loop if an error occured
            $transaction++;  # transaction counter

            {
                use bytes;
                my ( $port, $addr ) = unpack_sockaddr_in($fromaddr);
                my $ipaddr = inet_ntoa($addr);
                $self->Init->io->debug(
                    "Got a packet tr=$transaction src=$ipaddr:$port length="
                        . length($buf) );
            }

            my $dhcpreq = new Net::DHCP::Packet($buf);
            $dhcpreq->comment($transaction);

            my $messagetype
                = $dhcpreq->getOptionValue( DHO_DHCP_MESSAGE_TYPE() );

            if ( $messagetype eq DHCPDISCOVER() ) {
                $self->do_discover($dhcpreq);
            }
            elsif ( $messagetype eq DHCPREQUEST() ) {
                $self->do_request($dhcpreq);
            }
            elsif ( $messagetype eq DHCPINFORM() ) {

            }
            else {
                $self->Init->io->debug("Packet dropped");

                # bad messagetype, we drop it
            }
        };    # end of 'eval' blocks
        if ($@) {
            $self->Init->io->error("Caught error in main loop:$@");
        }

    }
    $self->Init->io->info("DHCPD server quit");
}

#=======================================================================
sub do_discover() {
    my $self = shift;
    my ($dhcpreq) = @_;
    my $sock_out;
    my ( $calc_ip, $calc_router, $calc_mask );

    # calculate address
    #    $calc_ip = "12.34.56.78";
    $calc_ip = $self->Init->interfaces->getIP( $self->iface );

    my $vendor = $dhcpreq->getOptionValue( DHO_VENDOR_CLASS_IDENTIFIER() );
    if ( $vendor !~ $VENDOR_ACCEPTED ) {
        $self->Init->io->debug("REQUEST rejected, unsupported VENDOR class");
        return;    # dropping packet
    }

    my $dhcpresp = new Net::DHCP::Packet(
        Comment                 => $dhcpreq->comment(),
        Op                      => BOOTREPLY(),
        Hops                    => $dhcpreq->hops(),
        Xid                     => $dhcpreq->xid(),
        Flags                   => $dhcpreq->flags(),
        Ciaddr                  => $dhcpreq->ciaddr(),
        Yiaddr                  => $calc_ip,
        Siaddr                  => $dhcpreq->siaddr(),
        Giaddr                  => $dhcpreq->giaddr(),
        Chaddr                  => $dhcpreq->chaddr(),
        DHO_DHCP_MESSAGE_TYPE() => DHCPOFFER(),
    );

    $self->Init->io->debug("Sending response");

    # Socket object keeps track of whom sent last packet
    # so we don't need to specify target address
    $self->Init->io->debug( "Sending OFFER tr=" . $dhcpresp->comment() );
    $sock_in->send( $dhcpresp->serialize() )
        || $self->Init->io->error("Error sending OFFER:$!")
        and return;

# TODO: you have to choose between sending back to sender or broadcasting to network

}

#=======================================================================
sub do_request() {
    my $self = shift;
    my ($dhcpreq) = @_;
    my $sock_out;
    my $calc_ip;
    my $dhcpresp;

    # $calc_ip = "12.34.56.78";
    $calc_ip = $self->Init->interfaces->getIP( $self->iface );

    my $vendor = $dhcpreq->getOptionValue( DHO_VENDOR_CLASS_IDENTIFIER() );
    if ( $vendor !~ $VENDOR_ACCEPTED ) {
        $self->Init->io->debug("REQUEST rejected, unsupported VENDOR class");
        return;    # dropping packet
    }

    # compare calculated address with requested address
    if ($calc_ip eq $dhcpreq->getOptionValue( DHO_DHCP_REQUESTED_ADDRESS() ) )
    {
        # address is correct, we send an ACK

        $dhcpresp = new Net::DHCP::Packet(
            Comment                 => $dhcpreq->comment(),
            Op                      => BOOTREPLY(),
            Hops                    => $dhcpreq->hops(),
            Xid                     => $dhcpreq->xid(),
            Flags                   => $dhcpreq->flags(),
            Ciaddr                  => $dhcpreq->ciaddr(),
            Yiaddr                  => $calc_ip,
            Siaddr                  => $dhcpreq->siaddr(),
            Giaddr                  => $dhcpreq->giaddr(),
            Chaddr                  => $dhcpreq->chaddr(),
            DHO_DHCP_MESSAGE_TYPE() => DHCPACK(),
        );
    }
    else {
        # bad request, we send a NAK
        $dhcpresp = new Net::DHCP::Packet(
            Comment                 => $dhcpreq->comment(),
            Op                      => BOOTREPLY(),
            Hops                    => $dhcpreq->hops(),
            Xid                     => $dhcpreq->xid(),
            Flags                   => $dhcpreq->flags(),
            Ciaddr                  => $dhcpreq->ciaddr(),
            Yiaddr                  => "0.0.0.0",
            Siaddr                  => $dhcpreq->siaddr(),
            Giaddr                  => $dhcpreq->giaddr(),
            Chaddr                  => $dhcpreq->chaddr(),
            DHO_DHCP_MESSAGE_TYPE() => DHCPNAK(),
            DHO_DHCP_MESSAGE(), "Bad request...",
        );
    }

    # Socket object keeps track of whom sent last packet
    # so we don't need to specify target address
    $self->Init->io->debug( "Sending OFFER tr=" . $dhcpresp->comment() );
    $sock_in->send( $dhcpresp->serialize() )
        || $self->Init->io->error("Error sending OFFER:$!")
        and return;

# TODO: you have to choose between sending back to sender or broadcasting to network

}

1;
