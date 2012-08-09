package Plugin::Sniffer;
use warnings;
use Nemesis::Process;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE	= "Sniffer Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS = qw(configure check_installation Process Use);    #NECESSARY

sub new {                                                        #NECESSARY
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
my $self=shift;
my $IO=$self->{'core'}->{'IO'};
my $section=$_[0];
$IO->print_title($MODULE." Helper");
if($section eq "configure"){
	$IO->print_title("nothing to configure here");
}


}

sub start {
    my $self = shift;
    my $IO   = $self->{'core'}->{'IO'};
    my $env  = $self->{'core'}->{'env'};

    # Starting basis of the module

    
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

sub Process {
    my $self = shift;
    my $IO= $self->{'core'}->{'IO'};

			
	my $process= new Nemesis::Process(
										type => 'system',# forked pipeline
										code=>join( ' ', @_ ),
										env=> $self->{'core'}->{'env'},
										IO => $IO);
	$process->start();
	sleep 4;

	 $IO->print_title("Testing process module functions with ". join( ' ', @_ ));
	 $IO->print_info("Is running: ".$process->is_running());
	 $IO->print_info("associated pid : ".$process->get_pid());
	 while($process->is_running()==1){
		$IO->print_info("Waiting the process stop"); sleep 1;
	 }
	 @output=$process->get_output();
	 $process->destroy();
	 print "@output"."\n";
		 


}

sub Use{
	my $self=shift;
	$self->{'core'}->{'IO'}->print_title("Test Module can access to loaded modules..");
	foreach my $module ( sort( keys %{ $self->{'core'}->{'ModuleLoader'}->{'modules'}} ) ) {
		$self->{'core'}->{'IO'}->debug($module);
    }
    $self->{'core'}->{'IO'}->print_info("");
    $self->{'core'}->{'IO'}->print_info("");

   	$self->{'core'}->{'IO'}->print_info("Also i can invoke functions to myself thru moduleLoader..\n\t Invoking help()");

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
