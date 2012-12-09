package Nemesis::Init;
{
	use Nemesis::Env;
	use Nemesis::Interfaces;
	use Nemesis::IO;
	use Nemesis::Process;
	use Nemesis::ModuleLoader;
	use Nemesis::Session;
	use Carp qw( croak );

	sub new
	{
		my $package = shift;
		bless( {}, $package );
		$package->{'Env'} = new Nemesis::Env;
		$package->{'Io'} =
			new Nemesis::IO( debug   => 1,
							 verbose => 0,
							 env     => $package->{'Env'}
			);
		$package->{'Interfaces'} =
			new Nemesis::Interfaces( IO => $package->{'Io'} );
		$package->{'Session'} =
			Nemesis::Session->new( IO         => $package->{'Io'},
								   interfaces => $package->{'Interfaces'},
								   env        => $package->{'Env'}
			);
		if ( $package->{'Session'}->exists("default_session") )
		{
			$package->{'Session'}->restore("default_session");
		} else
		{
			$package->{'Session'}->initialize("default_session");
		}
		$package->{'Io'}->set_session("default_session");
		$package->{'ModuleLoader'} =
			Nemesis::ModuleLoader->new( IO         => $package->{'Io'},
										interfaces => $package->{'Interfaces'},
										env        => $package->{'Env'},
										Session    => $package->{'Session'}
			);
		$package->{'Session'}->{'core'}->{'ModuleLoader'} =
			$package->{'ModuleLoader'};
		$package->{'Io'}->{'core'}->{'Session'} =
			$package->{'ModuleLoader'}->{'core'}->{'Session'};

#Load all plugins in plugin directory and passes to the construtor of the modules those objs
#
		if ( !$package->{'Env'}->check_root() )
		{
			$package->{'Io'}->print_alert(
					  "Insufficient permission, something can go really wrong switching to debug mode");
			$package->{'Io'}->set_debug(1);    #If no root given, debug on
		}
		
		$0 = "SpikeNemesis";
		
		return $package;
	}

	sub sighandler()
	{
		my $self = shift;
		$self->on_exit();
	}

	sub on_exit()
	{
		my $self = shift;
		if ( exists( $self->{'ModuleLoader'}->{'core'}->{'Session'} ) )
		{
			$self->{'ModuleLoader'}->{'core'}->{'Session'}->save();
		}
		$self->{'ModuleLoader'}->execute_on_all("clear");
		exit;
	}
}
1;
