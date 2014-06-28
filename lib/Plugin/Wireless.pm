package Plugin::Wireless;
use Nemesis::BaseModule -base;

our $VERSION          = '0.1a';
our $AUTHOR           = "mudler";
our $MODULE           = "Wireless plugin";
our $INFO             = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw(test wps rogue scan list);

has 'res' => sub { [] };

sub rogue {    #associate every probe
    my $self     = shift;
    my $device   = shift;
    my $Aircrack = $self->Init->ml->atom("Aircrack");
    $Aircrack->device($device);
    $Aircrack->monitor(1);
    push( @{ $self->res }, $Aircrack ) and return 1
        if ( $Aircrack->airbase(1) );
    return 0;
}

sub scan {
    my $self = shift;
    $self->Init->interfaces->wifi_scan();
    $self->list();
}

sub list {
    my $self = shift;
    my %Aps  = $self->Init->interfaces->getAPs();
    foreach my $k ( keys %Aps ) {
        $self->Init->io->info("Device: $k");
        foreach my $kk ( keys %{ $Aps{$k} } ) {
            $self->display_wifi( $Aps{$k}{$kk} );
        }
    }
}

sub monitor {    #associate every probe
    my $self     = shift;
    my $device   = shift;
    my $Aircrack = $self->Init->ml->atom("Aircrack");
    $Aircrack->device($device);
    push( @{ $self->res }, $Aircrack ) and return 1
        if ( $Aircrack->monitor(1) );
}

sub wps {
    my $self   = shift;
    my $device = shift;
    my $Target = shift;    #Mac address or essid
    my %Aps = $self->Init->interfaces->getAPs($device);

    $self->Init->io->debug_dumper( \%Aps );

    if ( $Target =~ /\:/ ) {
        #$Init->io->info()
        if ( exists $Aps{$Target} ) {
            $self->Init->io->info( "We have a match for " . $Target );
            $self->display_wifi( $Aps{$Target} );
        }
    }
    else {
        foreach my $mac ( keys %Aps ) {
            if ( $Aps{$mac}{"SSID"} =~ /$Target/i ) {
                $self->Init->io->info( "We have a match for " . $Target );
                $self->display_wifi( $Aps{$mac} );
            }
        }
    }
}

sub attack_wps() {
    my $self   = shift;
    my $Reaver = $self->Init->ml->atom("Reaver");
    $Reaver->channel("test");
    $self->Init->io->debug( $Reaver->_generateCommand() );
}

sub display_wifi() {
    my $self = shift;
    my $ap   = shift;
    $self->Init->io->info( $ap->{'SSID'} )
        if exists $ap->{'SSID'};
    $self->Init->io->print_tabbed( $ap->{'signal'}, 4 )
        if exists $ap->{'signal'};
    $self->Init->io->print_tabbed( $ap->{'security'}, 4 )
        if exists $ap->{'security'};
    $self->Init->io->print_tabbed( $ap->{'channel'}, 4 )
        if exists $ap->{'channel'};
}

sub auto_wps {

}

sub test {
    my $self   = shift;
    my $Reaver = $self->Init->ml->atom("Reaver");
    $Reaver->channel("test");
    $self->Init->io->debug( $Reaver->_generateCommand() );

}

sub clear {
    my $self = shift;

    # $_->monitor(0) for grep {$_->monitor_device ne ""} @{$self->res};
    foreach my $a ( @{ $self->res } ) {
        $a->monitor(0) if ( $a->monitor_device ne "" );

    }
}

1;
