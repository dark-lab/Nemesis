package Nemesis::Process;
{
    use Carp qw( croak );

    sub new {
        my $package = shift;
        bless( {}, $package );
        %{ $package->{'CONFIG'} } = @_;
        my $pid;
        my $output;
        croak "IO and environment must be defined\n" if ( !defined( $package->{'CONFIG'}->{'IO'} ) || !defined( $package->{'CONFIG'}->{'env'} ) );
        return $package;
    }

    sub start {
        my $self = shift;
        $self->{'INDEX'} = $self->generate_safe_index();

        if ( !defined( $self->{'CONFIG'}->{'type'} ) ) {
            croak "No type defined, aborting..";
        }
        else {
            if ( $self->{'CONFIG'}->{'type'} eq 'shared' ) {
                $self->shared_eval;
            }
            else {
                $self->fork;
            }
        }

    }



    sub stop() {
        my $self = shift;
        if (   ( $self->{'CONFIG'}->{'type'} eq 'fork' )
            or ( $self->{'CONFIG'}->{'type'} eq 'eval' ) )
        {
            kill 9 => $self->get_pid();
        }
        
        $self->destroy();
    }
    
	sub destroy(){
		
		my $self=shift;
		unlink($self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".lock");
		unlink($self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".out");
		unlink($self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".pid");

		
	}

    sub is_running() {
        my $self = shift;

       if( -e $self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".lock") {
		   return 1;
	   } else {
		   return 0;
	   }
    }

    sub generate_safe_index{
		my $self=shift;
		my $generated_index = int(rand(9000));
        while(-e $self->{'CONFIG'}->{'env'}->tmp_dir()."/".$generated_index.".lock"){
			$generated_index = int(rand());
		}
		open FILE,">".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$generated_index.".lock";
		print FILE "LOCKED on ".$self->{'CONFIG'}->{'env'}->time()."\n";
		close FILE;
		return $generated_index;
	}
	

    sub fork {
        my $self = shift;
        croak "You have not run start..\n" if !exists($self->{'INDEX'});
        if ( my $pid = fork ) {
            waitpid( $pid, 0 );
        }
        else {
            if (fork) {
                exit;
            }
            else {
								
				$self->save_pid($$);
                if ( $self->{'CONFIG'}->{'type'} eq 'eval' ) {
					my $output;
					open STDERR, '>&STDOUT';
					open( OUTPUT, ">", \$output ) or die "Can't open OUTPUT: $!";
					select OUTPUT;
                    eval( $self->{'CONFIG'}->{'code'} );
                    select STDOUT;
					close(OUTPUT);
                }
                else {
					
					open CMD, "$self->{'CONFIG'}->{'code'}  2>&1  |" or croak "Failed to open pipeline";
					while(<CMD>) {
						push(@out,$_);
					}
                }
				if(@out){
					$self->save_output(@out);
				} elsif ($out) {
					$self->save_output($out);
				} else {
					$self->save_output("No output cached");
				}
				$self->remove_lock();
            }
            exit;
        }

    }
    sub shared_eval {
        croak "You have not run start..\n" if !exists($self->{'INDEX'});
        #one eval who shares resources,
        my $self = shift;
        my $output;
        open STDERR, '>&STDOUT';
        open( OUTPUT, ">", \$output ) or die "Can't open OUTPUT: $!";
        select OUTPUT;
        eval( $self->{'CONFIG'}->{'code'} );
        select STDOUT;
        close(OUTPUT);
        $self->save_output($output);
        $self->remove_lock();

    }
    sub save_pid(){
		my $self=shift;
		open FILE,">".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".pid";
		print FILE $_[0];
		close FILE;
	}
	
	sub save_output(){
		my $self=shift;
		if($_[1]){
			open FILE,">".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".out";
			print FILE @_;
			close FILE;
		} else {
			open FILE,">".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".out";
			print FILE $_[0];
			close FILE;
		}

	}
	
	sub get_pid(){
		my $self=shift;
		open FILE,"<".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".pid";
		my @pid=<FILE>;
		close FILE;
		return "@pid";
	}
	
	sub get_output(){
		my $self=shift;
		if(-e $self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".out"){
			open FILE,"<".$self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".out";
			my @out=<FILE>;
			close FILE;
			return @out;
		} else {
		return 0;
		}
		
	}

	sub remove_lock(){
		my $self=shift;
		unlink($self->{'CONFIG'}->{'env'}->tmp_dir()."/".$self->{'INDEX'}.".lock");
		
	}


}

1;

__END__
