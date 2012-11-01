package Plugin::Test_Module;
use warnings;
use Nemesis::Process;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Dummy Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS =
    qw(configure check_installation Process Use where module);    #NECESSARY

sub new {                                                         #NECESSARY
     #Usually new(), export_public_methods() and help() can be copyed from other plugins
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

sub clear {
    1;
} # Do what you want to do here when the nemesis framework is going to be shut down.

sub start {
    my $self = shift;
    my $IO   = $self->{'core'}->{'IO'};
    my $env  = $self->{'core'}->{'env'};

    # Starting basis of the module

}

sub where {
    my $self   = shift;
    my $output = $self->{'core'}->{'IO'};
    my $env    = $self->{'core'}->{'env'};

    my $path = $env->whereis( $_[0] );
    $output->print_info( $_[0] . " bin is at $path" );

}

sub module {
    my $self = shift;

# Example of Module Loading
#
# you can invoke a module by:
# $self->{'core'}->{'ModuleLoader'}->{'modules'}->{'Test_Module'}->help();
# but with this method, there is an istance of the module already loaded in memory, so data can be different thru sessions.
# If you want to load a new istance do as follow:

    my $NetManipulator =
        $self->{'core'}->{'ModuleLoader'}->loadmodule('NetManipulator');
    $NetManipulator->video_redirect();

#This is due to the modularity of the framework, a plugin has public functions (methods that can be called by CLI)
#and if the private functions needs to do something specific with other modules, can load module more than once.
    my $Process = $self->{'core'}->{'ModuleLoader'}->loadmodule('Process');
    $Process->info();

}

sub info {
    my $self = shift;

    my $IO  = $self->{'core'}->{'IO'};
    my $env = $self->{'core'}->{'env'};

    # A small info about what the module does
    $IO->print_info("->\tDummy module v$VERSION ~ $AUTHOR ~ $INFO");
}

sub configure {    #postgre pc_hba.conf

    my $self  = shift;
    my $var   = $_[0];
    my $value = $_[1];
    $self->{'CONFIG'}->{$var} = $value;
    return;

}

sub Process {
    my $self    = shift;
    my $IO      = $self->{'core'}->{'IO'};
    my $Process = $self->{'core'}->{'ModuleLoader'}->loadmodule('Process');

    $Process->set(
        type => 'system',                   # forked pipeline
        code => join( ' ', @_ ),
        env  => $self->{'core'}->{'env'},
        IO   => $IO
    );
    $Process->start();

    $IO->print_title(
        "Testing process module functions with " . join( ' ', @_ ) );
    $IO->print_info( "Is running: " . $Process->is_running() );
    $IO->print_info( "associated pid : " . $Process->get_pid() );
    $IO->process_status($Process);
    while ( $Process->is_running() == 1 ) {
        $IO->print_info("Waiting the process stop");
        sleep 1;
    }
    @output = $Process->get_output();
    $Process->destroy();
    print "@output" . "\n";

}

sub Use {
    my $self = shift;
    $self->{'core'}->{'IO'}
        ->print_title("Test Module can access to loaded modules..");
    foreach my $module (
        sort( keys %{ $self->{'core'}->{'ModuleLoader'}->{'modules'} } ) )
    {
        $self->{'core'}->{'IO'}->debug($module);
    }
    $self->{'core'}->{'IO'}->print_info("");
    $self->{'core'}->{'IO'}->print_info("");

    $self->{'core'}->{'IO'}->print_info(
        "Also i can invoke functions to myself thru moduleLoader..\n\t Invoking help()"
    );

    $self->{'core'}->{'ModuleLoader'}->{'modules'}->{'Test_Module'}->help();
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
