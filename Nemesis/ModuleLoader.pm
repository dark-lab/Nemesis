package Nemesis::ModuleLoader;
use Carp qw( croak );
use Storable qw(dclone freeze thaw);
use TryCatch;
use Scalar::Util qw(blessed);

#external modules
my $base = { 'path'         => 'Plugin',
			 'pwd'          => './',
			 'main_modules' => 'Nemesis'
};
our $Init;

sub new
{
	my $class = shift;
	my $self = { 'Base' => $base };
	%{$package} = @_;
	croak 'No init' if !exists( $package->{'Init'} );
	$Init = $package->{'Init'};
	$self->{'Base'}->{'pwd'} = $Init->getEnv()->{'ProgramPath'} . "/";
	return bless $self, $class;
}

sub execute
{
	my $self    = shift;
	my $module  = shift @_;
	my $command = shift @_;
	my @ARGS    = @_;
	my $currentModule=$self->{'modules'}->{$module};
	try
	{
		if ( UNIVERSAL::can( $currentModule, $command ) )
		{
				$currentModule->$command(@ARGS);
				$Init->getSession()->execute_save( $module, $command, @ARGS )
				if $module ne "session";
		} else
		{
			$Init->getIO->debug("$module doesn't provide $command");
		}
	}
	catch($error) {
		$Init->getIO->print_error("Something went wrong calling the method '$command' on '$module': $error");
	};
}

sub execute_on_all
{
	my $self    = shift;
	my $met     = shift @_;
	my @command = @_;
	foreach my $module ( sort( keys %{ $self->{'modules'} } ) )
	{
		$self->execute($module,$met,@command);
	}
}

sub export_public_methods()
{
	my $self = shift;
	my @OUT;
	my @PUBLIC_FUNC;
	foreach my $module ( sort( keys %{ $self->{'modules'} } ) )
	{
		@PUBLIC_FUNC = ();
		try
		{
			@PUBLIC_FUNC =
				eval { $self->{'modules'}->{$module}->export_public_methods() };
			foreach my $method (@PUBLIC_FUNC)
			{
				$method = $module . "." . $method;
			}
			push( @OUT, @PUBLIC_FUNC );
		}
		catch($error) {
			$Init->getIO()->print_error(
						  "Error $error raised when populating public methods");
		};
	}
	return @OUT;
}

sub listmodules
{
	my $self = shift;
	my $IO   = $Init->getIO();
	$IO->print_title("List of modules");
	foreach my $module ( sort( keys %{ $self->{'modules'} } ) )
	{
		$IO->print_info("$module");
		$self->{'modules'}->{$module}->info()
			; #so i can call also configure() and another function to display avaible settings!
	}
}

sub loadmodule()
{
	my $self        = shift;
	my $module      = $_[0];
	my $IO          = $Init->getIO();
	my $plugin_path = $self->{'Base'}->{'pwd'} . $self->{'Base'}->{'path'};
	my $modules_path =
		$self->{'Base'}->{'pwd'} . $self->{'Base'}->{'main_modules'};
	my $base;
	if ( -e $plugin_path . "/" . $module . ".pm" )
	{
		$base = $self->{'Base'}->{'path'};
	} elsif ( -e $modules_path . "/" . $module . ".pm" )
	{
		$base = $self->{'Base'}->{'main_modules'};
	} else
	{
		return ();
	}

	#$IO->debug("Module $module found in $base");
	my $object = "$base" . "::" . "$module";
	try
	{
		do($object);
		$object=$object->new( Init => $Init );
	}
	catch($error) {
		$Init->getIO()
			->print_error("Something went wrong loading $object: $error");
			return ();
	}

	# if($object eq ""){
	# 	$Init->getIO()->print_alert("Module $module NOT loaded");
	# 	return();
	# }

		#NOTE: prepare sub invoked after initialization
	if ( eval{ $object->can("prepare") })
	{
		$object->prepare;
	} else
	{
		$Init->getIO()->debug("No prepare for $object");
	}
	$Init->getIO()->debug("Module $module correctly loaded");
	return $object;
}

sub loadmodules
{
	my $self = shift;
	my @modules;
	my $IO   = $Init->getIO();
	my $path = $self->{'Base'}->{'pwd'} . $self->{'Base'}->{'path'};
	local *DIR;
	if ( !opendir( DIR, "$path" ) )
	{
		$IO->print_error(
					   "[LOADMODULES] - (*) No such file or directory ($path)");
		croak "No such file or directory ($path)";
	}
	my @files = grep( !/^\.\.?$/, readdir(DIR) );
	closedir(DIR);
	my $modules;
	my $mods = 0;
	foreach my $f (@files)
	{
		my $base = $path . "/" . $f;
		my ($name) = $f =~ m/([^\.]+)\.pm/;
		try
		{
			if ( exists( $self->{'modules'}->{$name} ) )
			{
				delete $INC{ $path . "/" . $name };
				delete $self->{'modules'}->{$name};
			}
			my $result = do($base);
			if ( $self->isModule($base) )
			{
				$self->{'modules'}->{$name} = $self->loadmodule($name);
				$mods++;
			} else
			{
				$Init->getIO()->print_alert("$base it's not a Nemesis module");
			}
		}
		catch($error) {
			$IO->print_error($error);
				delete $INC{ $path . "/" . $name };
				next;
		};
	}
	$IO->print_info("> $mods modules available. Double tab to see them\n");

	#delete $self->{'modules'};
	return 1;
}

sub isModule()
{
	my $self   = shift;
	my $module = $_[0];
	open my $MODULE, "<" . $module
		or $Init->getIO()->print_alert("$module can't be opened");
	my @MOD = <$MODULE>;
	close $MODULE;
	foreach my $rigo (@MOD)
	{
		if ( $rigo =~ /(?<![#|#.*|.*#])[nemesis_module|nemesis_moose_module]/ )
		{
			return 1;
		}
	}
	return 0;
}
1;
