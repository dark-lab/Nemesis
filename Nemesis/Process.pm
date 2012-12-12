package Nemesis::Process;
{
	use Carp qw( croak );
	use Unix::PID;
	use Data::Dumper;
	our $Init;

	sub new
	{
		my $package = shift;
		bless( {}, $package );
		%{$package} = @_;
		my $pid;
		my $output;
		$Init = $package->{'Init'};
		return $package;
	}

	sub info
	{
		my $self = shift;
		$Init->getIO()->print_info("Process: a main module.");
	}

	sub start
	{
		my $self = shift;
		my $state;
		$self->{'CONFIG'}->{'INDEX'} = $self->generate_lock()
			if !exists( $self->{'CONFIG'}->{'INDEX'} );
		if ( !defined( $self->{'CONFIG'}->{'type'} ) )
		{
			croak "No type defined, aborting..";
		} else
		{
			if ( $self->{'CONFIG'}->{'type'} eq 'daemon' )
			{
				$state = $self->daemon();
			} else
			{
				$state = $self->fork();
			}
		}
		$Init->getIO()->debug( "Running: " . $self->{'CONFIG'}->{'code'} );
		return $state ? $self->get_id() : ();
	}

	sub stop()
	{
		my $self = shift;
		if ( $self->get_pid() )
		{
			kill 9 => $self->get_pid();
			kill( 9, $self->get_pid() );
		}
	}

	sub destroy()
	{
		my $self = shift;
		$self->stop();
		unlink(   $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'}
				. ".lock" );
		unlink(   $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'}
				. ".out" );
		unlink(   $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'}
				. ".pid" );
	}

	sub is_running()
	{
		my $self = shift;
		my $pid  = Unix::PID->new();
		if ( $self->get_pid and $pid->is_pid_running( $self->get_pid() ) )
		{
			return 1;
		} else
		{
			return 0;
		}
	}

	sub generate_lock
	{
		my $self            = shift;
		my $generated_index = int( rand(9000) );
		while (
			  -e $Init->getEnv()->tmp_dir() . "/" . $generated_index . ".lock" )
		{
			$generated_index = int( rand() );
		}
		open FILE,
			">" . $Init->getEnv()->tmp_dir() . "/" . $generated_index . ".lock";
		foreach my $key ( sort( keys %{ $self->{'CONFIG'} } ) )
		{
			next if $key eq "ID";
			next if $key eq "IO";
			next if $key eq "env";
			print FILE "$key:" . $self->{'CONFIG'}->{$key} . "\n";
		}
		print FILE "TIME:" . $Init->getEnv()->time() . "\n";
		close FILE;
		return $generated_index;
	}

	sub load
	{
		my $self = shift;
		my $id   = $_[0];
		open FILE, "<" . $Init->getEnv()->tmp_dir() . "/" . $id . ".lock";
		my @FILE = <FILE>;
		close FILE;
		chomp(@FILE);
		foreach my $rigo (@FILE)
		{
			my ( $key, $value ) = split( /:/, $rigo );
			$self->{'CONFIG'}->{$key} = $value;
		}
	}

	sub get_var()
	{
		my $self = shift;
		return $self->{'CONFIG'}->{ $_[0] };
	}

	sub daemon
	{
		my $self = shift;
		croak "You have not run start..\n"
			if !exists( $self->{'CONFIG'}->{'INDEX'} );
		my $this_pid = Unix::PID->new();
		my $p;
		my $cmd =
			$Init->getIO()->generate_command( $self->{'CONFIG'}->{'code'} );

		#$Init->getIO()->set_debug(1);
		if ( system($cmd) == 0 )
		{
			$Init->getIO()
				->debug("Daemon released me, now i try to search for $cmd");
			if ( $p = $self->pidof($cmd) )
			{
				$self->save_pid($p);
				$self->save("Daemon mode\n");
				return 1;
			} else
			{
				$Init->getIO()
					->print_error(
					"PID Cannnot be found destroying the process, look at your process activity and kill manually: "
						. $self->{'CONFIG'}->{'code'} );
				$self->destroy();
				return ();
			}
		} else
		{
			$Init->getIO()
				->print_error("Something went wrong, i'm destroying myself");
			$self->destroy();
			return ();
		}

		#$Init->getIO()->set_debug(0);
	}

	sub fork
	{
		my $self = shift;
		my $p;
		croak "You have not run start..\n"
			if !exists( $self->{'CONFIG'}->{'INDEX'} );
		if ( my $pid = fork )
		{
			waitpid( $pid, 0 );
		} else
		{
			if (fork)
			{
				exit;
			} else
			{
				my $this_pid = Unix::PID->new();
				my $cmd =
					$Init->getIO()
					->generate_command( $self->{'CONFIG'}->{'code'} );
				open( $handle, "$cmd  2>&1 |" )
					or croak "Failed to open pipeline $!";
				if ( $p = $self->pidof($cmd) )
				{
					$self->save_pid($p);
					while (<$handle>)
					{
						$self->save($_);
					}
					$self->remove_lock();
				} else
				{
					$Init->getIO()
						->print_alert("Can't get pid of the forked process");
					$self->destroy();
					close($handle);
				}
			}
			exit;
		}
	}

	sub pidof($)
	{
		my $self     = shift;
		my $this_pid = Unix::PID->new();
		my $p;
		my @PIECES = split( /\s+/, $_[0] );
		my %matr;
		$Init->getIO()->debug( "getting the pid of: " . $PIECES[0] );
		foreach my $piece (@PIECES)
		{
			my @FOUND_PIDS = $this_pid->get_pidof($piece);
			foreach my $found_pid (@FOUND_PIDS)
			{
				$matr{$found_pid}++;
			}
		}
		foreach ( sort { $matr{$b} <=> $matr{$a} } ( keys(%matr) ) )
		{
			$p = $_;
			last;
		}    # end-foreach
		$Init->getIO()->debug( "MAX PID " . $p );
		return ($p);
	}

	sub save_pid()
	{
		my $self = shift;
		open FILE,
			  ">"
			. $Init->getEnv()->tmp_dir() . "/"
			. $self->{'CONFIG'}->{'INDEX'} . ".pid";
		print FILE $_[0];
		close FILE;
		$self->{'CONFIG'}->{'PID'} = $_[0];
	}

	sub save()
	{
		my $self = shift;
		open FILE,
			  ">>"
			. $Init->getEnv()->tmp_dir() . "/"
			. $self->{'CONFIG'}->{'INDEX'} . ".out";
		print FILE $_[0];
		close FILE;
	}

	sub save_output()
	{
		my $self = shift;
		if ( $_[1] )
		{
			open FILE,
				  ">"
				. $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'} . ".out";
			print FILE @_;
			close FILE;
		} else
		{
			open FILE,
				  ">"
				. $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'} . ".out";
			print FILE $_[0];
			close FILE;
		}
	}

	sub get_pid()
	{
		my $self = shift;
		open FILE,
			  "<"
			. $Init->getEnv()->tmp_dir() . "/"
			. $self->{'CONFIG'}->{'INDEX'} . ".pid";
		my @pid = <FILE>;
		close FILE;
		return $pid[0] if ( $pid[0] );
	}

	sub get_output_file()
	{
		my $self = shift;
		return
			  $Init->getEnv()->tmp_dir() . "/"
			. $self->{'CONFIG'}->{'INDEX'} . ".out";
	}

	sub get_output()
	{
		my $self = shift;
		if (   -e $Init->getEnv()->tmp_dir() . "/"
			 . $self->{'CONFIG'}->{'INDEX'}
			 . ".out" )
		{
			open FILE,
				  "<"
				. $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'} . ".out";
			my @out = <FILE>;
			close FILE;
			return "@out";
		} else
		{
			return 0;
		}
	}

	sub get_id()
	{
		my $self = shift;
		return $self->{'CONFIG'}->{'INDEX'};
	}

	sub output()
	{
		my $self = shift;
		if (   -e $Init->getEnv()->tmp_dir() . "/"
			 . $self->{'CONFIG'}->{'INDEX'}
			 . ".out" )
		{
			open FILE,
				  "<"
				. $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'} . ".out";
			return FILE;
		} else
		{
			return 0;
		}
	}

	sub remove_lock()
	{
		my $self = shift;
		unlink(   $Init->getEnv()->tmp_dir() . "/"
				. $self->{'CONFIG'}->{'INDEX'}
				. ".lock" );
	}

	sub setParam()
	{
		my $self  = shift;
		my $VAR   = $_[0];
		my $VALUE = $_[1];
		$self->{'CONFIG'}->{$VAR} = $VALUE;
	}

	sub set()
	{
		my $self = shift;
		%{ $self->{'CONFIG'} } = @_;
	}
}
1;
__END__
