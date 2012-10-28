package Plugin::Metasploit;
use warnings;
use Carp qw( croak );
use Nemesis::Process;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Metasploit Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS =
    qw(configure check_installation status where stop status_pids sniff spoof strip mitm)
    ;    #NECESSARY
    
    
my $CONF={
    VARS => {
                MSFRPCD_USER => 'spike',
                MSFRCPD_PASS => 'spiketest',
                MSFRCPD_PORT => 5553
                }
    
    };
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
    foreach my $dev ( keys %{ $self->{'process'} } ) {
        foreach my $type ( keys %{ $self->{'process'}->{$dev} } ) {
            $Process->destroy();
            delete $self->{'process'}->{$dev}->{$type};
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

sub msfrpcd {
    my $self  = shift;
    my $which = $_[0];
    my $Io    = $self->{'core'}->{'IO'};
    if ( $which eq "stop" ) {
        if ( exists( $self->{'process'}->{'msfrpcd'} ) ) {
            $self->{'process'}->{'msfrpcd'}->destroy();
            delete $self->{'process'}->{'msfrpcd'};
        }
        else {
            $Io->print_alert("Process already stopped");
        }
    }
    else {
        my $code = 'msfrpcd -U '.$CONF{'VAR'}{'MSFRPCD_USER'}.' -P '.$CONF{'VAR'}{'MSFRPCD_PASS'}.' -p '.$CONF{'VAR'}{'MSFRPCD_PORT'}.' -S';
        $Io->print_info("Starting msfrpcd service.");
        my $Process =
            $self->{'core'}->{'ModuleLoader'}->loadmodule('Process');
        $Process->set(
            type => 'daemon',                   # forked pipeline
            code => $code,
            env  => $self->{'core'}->{'env'},
            IO   => $IO
        );
        $self->{'process'}->{'msfrpcd'} = $Process;
        $Io->print_info("Service msfrcpd started");
    }
}

sub status {
    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    my $process;

    foreach my $dev ( keys %{ $self->{'process'} } ) {
        $self->service_status($service);
    }

}

sub service_status() {
    my $self   = shift;
    my $dev    = $_[0];
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    foreach my $service ( keys %{ $self->{'process'} } ) {
        $output->process_status( $self->{'process'}->{$service} );
    }
}

sub stop {

    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};
    my $dev    = $_[0];
    my $group  = $_[1];
    if ( !defined($dev) ) {
        $output->print_alert("You must provide at least a device");

    }
    else {
        if ( defined($group) ) {
            $output->print_info(
                "Stopping all activities on " . $dev . " for $group" );
            my $process = $self->{'process'}->{$dev}->{$group};
            $process->destroy();
            delete $self->{'process'}->{$dev}->{$group};

        }
        else {
            foreach my $process ( keys %{ $self->{'process'}->{$dev} } ) {
                $output->print_title( "Stopping $process on " . $dev . "" );
                $self->{'process'}->{$dev}->{$process}->destroy();
                delete $self->{'process'}->{$dev}->{$process};
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
