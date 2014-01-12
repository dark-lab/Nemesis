package Plugin::DHCPD;

use Nemesis::BaseModule -base;

our $VERSION          = '0.1a';
our $AUTHOR           = "mudler";
our $MODULE           = "DHCP Server plugin";
our $INFO             = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw(start stop);

has 'DHCPD';

sub start {
    my $self  = shift;
    my $Iface = shift;

    $Io->print_info("Starting DHCPD service.");
    my $Inst = $self->Init->ml->atom("DHCPD");
    $Inst->iface($Iface);
    my $Process
        = $self->Init->ml->loadmodule('Process');   ##Carico il modulo process
    $Process->set(
        type     => 'thread',                       # tipologia demone
        instance => $Inst                           # linea di comando...
    );
    if ( $Process->start() ) {                      #Avvio
        $self->Init->io->info("Thread running");
        $self->DHCPD($Process);
    }
    else {
        $self->Init->io->error("Thread failed to start");

    }
}

sub stop {
    my $self = shift;
    $self->Init->io->info("stopping DHCPD thread (if any)");
    return $self->DHCPD->destroy if defined $self->DHCPD;
}

1;
