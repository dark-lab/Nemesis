package Nemesis::ModuleLoader;
use Carp qw( croak );
use Storable qw(dclone freeze thaw);

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

	# my $object  = "$self->{'Base'}->{'path'}::$module";
	#eval( "$self->{'Base'}->{'path'}::$module"->$command(@_) );
	$self->{'modules'}->{$module}->$command(@_);
	$Init->getSession()->execute_save( $module, $command, @_ )
		if $module ne "session";

# TODO: Questo è un modo per scavalcare il problema... salvo la history e la ripristino..
	if ($@)
	{
		$Init->getIO->print_error("Something went wrong with $command: $@");
	}
}

sub execute_on_all
{
	my $self    = shift;
	my $met     = shift @_;
	my @command = @_;
	foreach my $module ( sort( keys %{ $self->{'modules'} } ) )
	{
		eval("$self->{'modules'}->{$module}->$met(@command)");
		if ($@)
		{
			$Init->getIO->print_error(
				"Something went wrong calling the method '$met' on '$module': $@"
			);
		}
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
		@PUBLIC_FUNC =
			eval { $self->{'modules'}->{$module}->export_public_methods() };
		foreach my $method (@PUBLIC_FUNC)
		{
			$method = $module . "." . $method;
		}
		push( @OUT, @PUBLIC_FUNC );
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
	$IO->debug("Module $module found in $base");
	my $object = "$base" . "::" . "$module";
	$object = eval {
		my $o     = dclone( \$object );
		my $realO = $$o;
		return $realO->new( Init => $Init );
	};
	if ($@)
	{
		$Init->getIO()->print_error("Something went wrong: $@");
		return ();
	} else
	{
		$Init->getIO()->debug("Module $module correctly loaded");
		return $object;
	}
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
		return "[LOADMODULES] - (*) No such file or directory ($path)";
	}
	my @files = grep( !/^\.\.?$/, readdir(DIR) );
	closedir(DIR);
	my $modules;
	my $mods = 0;
	foreach my $f (@files)
	{
		my $base = $path . "/" . $f;
		my ($name) = $f =~ m/([^\.]+)\.pm/;
		my $result = do($base);
		if ($@)
		{
			$IO->print_error($@);
			delete $INC{ $path . "/" . $name };
			next;
		}
		$self->{'modules'}->{$name} = $self->loadmodule($name);
		$mods++;
	}
	$IO->print_info("> $mods modules available. Double tab to see them\n");

	# delete $self->{'modules'};
	return 1;
}
1;
