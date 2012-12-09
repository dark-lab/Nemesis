package Nemesis::MInit;
{
	use Moose;
	use Nemesis::Env;
	use Nemesis::Interfaces;
	use Nemesis::IO;
	use Nemesis::Process;
	use Nemesis::ModuleLoader;
	use Nemesis::Session;
  has 'Env' => (
      is      => 'rw',
      isa     => 'Nemesis::Env',
      handles => [qw( new scan_env path )],
  );

    
    
    
    after 'new' => sub {
		my $package = shift;
		$package->Env->scan_env() ;
		$package->Io( Nemesis::IO->new( debug   => 1,
										verbose => 0,
										env     => $package->Env(),
					  )
		);
		$package->Interfaces( new Nemesis::Interfaces( IO => $package->Io() ) );
		$package->Session( new( IO         => $package->Io(),
								interfaces => $package->Interfaces(),
								Env        => $package->Env()
						   )
		);
		if ( $package->Session->exists("default_session") )
		{
			$package->Session->restore("default_session");
		} else
		{
			$package->Session->initialize("default_session");
		}
		$package->Io->set_session("default_session");
		$package->ModuleLoader =
			Nemesis::ModuleLoader->new( IO         => $package->Io(),
										interfaces => $package->Interfaces(),
										env        => $package->Env(),
										Session    => $package->Session()
			)
			; #Load all plugins in plugin directory and passes to the construtor of the modules those objs
		      #
		if ( !$package->Env->check_root() )
		{
			$package->Io->print_alert(
					  "Insufficient permission, something can go really wrong");
			$package->Io->set_debug(1);    #If no root given, debug on
		}
		}
}
1;
