package Nemesis::Process;
{
    use forks;

    # use forks::shared;
    #    share($Init);
    #TODO: Add tags to processes!  For analyzer.
    #TODO: Have a look to IPC::Run and IPC::Open3
    use Carp qw( croak );
    ###### Major change api
    ### now that we have two separate branch, one for master
    ### and one for minimal (so we now can assume that you have good resources on master and more dependency) we can switch to open ipc3
    ### developer happines :)
    use IPC::Open3;

    use Unix::PID;
    use Data::Dumper;
    use Scalar::Util 'reftype';
    our $Init;

    sub new {
        my $package = shift;
        bless( {}, $package );
        %{$package} = @_;
        my $pid;
        my $output;
        $Init = $package->{'Init'};
        return $package;
    }

    sub info {
        my $self = shift;
        $Init->getIO()->print_info("Process: a main module.");
    }

    sub start {
        my $self = shift;
        my $state;
        $self->{'CONFIG'}->{'INDEX'} = $self->generate_lock()
            if !exists( $self->{'CONFIG'}->{'INDEX'} );
        if ( !defined( $self->{'CONFIG'}->{'type'} ) ) {
            croak "No type defined, aborting..";
        }
        else {
            if ( $self->{'CONFIG'}->{'type'} eq 'daemon' ) {
                $Init->getIO()->debug("Starting syscall.. ");

                $state = $self->daemon();
            }
            elsif ( $self->{'CONFIG'}->{'type'} eq 'thread' ) {
                $Init->getIO()->debug("Starting job.. ");

                $self->thread();

            }
            else {
                ##Daemon now replaces forks legacy functionality ;)
                # in future will be removed
                $Init->getIO()->debug("Starting fork.. ");
                $state = $self->fork();
            }
        }
        return $state ? $self->get_id() : ();
    }

    sub getInstance() {
        my $self = shift;
        if ( $self->{'CONFIG'}->{'type'} eq 'thread' ) {
            return $self->{'INSTANCE'};
        }
    }

    sub thread() {
        my $self = shift;
        $Init->io->debug("Starting the thread");

        if ( exists( $self->{'CONFIG'}->{'instance'} ) ) {
            $Init->getIO()->debug("Starting a thread for ".$self->{'CONFIG'}->{'instance'});
            $self->{'INSTANCE'} = threads->new(
                sub {
                    my $instance = shift;
                    $instance->run();
                },
                $self->{'CONFIG'}->{'instance'}
            );
        }
        elsif ( exists( $self->{'CONFIG'}->{'code'} ) ) {

            if ( reftype( $self->{'CONFIG'}->{'code'} ) eq "CODE" ) {

                my $code = $self->{'CONFIG'}->{'code'};
                $self->{'INSTANCE'}
                    = threads->new( \&$code, $self->{'args'} );
            }
            else {

                $self->{'INSTANCE'} = threads->new(
                    sub {
                        eval( $self->{'CONFIG'}->{'code'} );
                    },
                    $self->{'args'}
                );
            }
        }
        elsif ( exists( $self->{'CONFIG'}->{'module'} ) ) {

            #TODO: Will even start?
            $self->{'CONFIG'}->{'module'} =~ s/\:\:/\//g;
            my @LOADED_LIBS = $Init->getModuleLoader()->getLoadedLib();
            foreach my $Lib (@LOADED_LIBS) {

                #$self->{'CONFIG'}->{'module'}=~s/\//\:\:/g;

                if ( $Lib =~ $self->{'CONFIG'}->{'module'} ) {
                    my $Module = $self->{'CONFIG'}->{'module'};
                    $Init->getIO()->debug("i handle that");
                    open HANDLE, "<" . $Lib;
                    @CODE = <HANDLE>;
                    close HANDLE;

                    $Init->getIO()->debug("@CODE");

                    # $Module =~ s/\//\:\:/g;
                    $self->{'INSTANCE'} = threads->new(
                        sub {
                            my $instance = $Init->getModuleLoader()
                                ->loadmodule($Module);
                            $instance->run();
                        },
                        [$Init]
                    );

                }
            }
        }
    }

    sub detach() {
        my $self = shift;
        if ( exists( $self->{'INSTANCE'} ) ) {
            $Init->io->debug( "Detaching", $self->{'CONFIG'}->{'INDEX'} );
            $self->{'INSTANCE'}->detach();
        }
    }

    sub join() {
        my $self = shift;
        if ( exists( $self->{'INSTANCE'} ) ) {
            $Init->io->debug( "Joining", $self->{'CONFIG'}->{'INDEX'} );
            $self->{'INSTANCE'}->join();
        }
    }

    sub stop() {
        my $self = shift;
        if ( exists( $self->{'INSTANCE'} ) ) {
            $Init->io->debug( "Stopping instance " . $self->{'INSTANCE'},
                $self->{'CONFIG'}->{'INDEX'} );

            #$self->{'INSTANCE'}->cancel();
            $self->{'INSTANCE'}->kill("TERM");

            $Init->io->debug(
                "waiting for instance " . $self->{'INSTANCE'} . " to join" );
            #$self->join();
            $self->detach();
            $Init->io->debug( "exit: " . $self->{'INSTANCE'} );
            delete( $self->{'INSTANCE'} );
        }
        if ( $self->get_pid() ) {
            $Init->io->debug( "Stopping pid " . $self->get_pid() );

            kill 9 => $self->get_pid();
            kill( 9, $self->get_pid() );
            waitpid($self->get_pid(),0);#to clean defuncts
        }
    }

    sub destroy() {
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
        $Init->io->debug(
            "Deleted: "
                . CORE::join( "\t",
                $Init->getEnv()->tmp_dir() . "/"
                    . $self->{'CONFIG'}->{'INDEX'} . ".lock",
                $Init->getEnv()->tmp_dir() . "/"
                    . $self->{'CONFIG'}->{'INDEX'} . ".out",
                $Init->getEnv()->tmp_dir() . "/"
                    . $self->{'CONFIG'}->{'INDEX'}
                    . ".pid" )

        );
    }

    sub is_running() {
        my $self = shift;
        if ( exists( $self->{'INSTANCE'} ) ) {
            return $self->{'INSTANCE'}->is_running();
        }
        else {
            my $pid = Unix::PID->new();
            if ( $self->get_pid and $pid->is_pid_running( $self->get_pid() ) )
            {
                return 1;
            }
            else {
                return 0;
            }
        }
    }

    sub generate_lock {
        my $self            = shift;
        my $generated_index = int( rand(9000) );
        while (
            -e $Init->getEnv()->tmp_dir() . "/" . $generated_index . ".lock" )
        {
            $generated_index = int( rand() );
        }
        open FILE,
              ">"
            . $Init->getEnv()->tmp_dir() . "/"
            . $generated_index . ".lock";
        foreach my $key ( sort( keys %{ $self->{'CONFIG'} } ) ) {
            next if $key eq "ID";
            next if $key eq "IO";
            next if $key eq "env";
            print FILE "$key:" . $self->{'CONFIG'}->{$key} . "\n";
        }
        print FILE "TIME:" . $Init->getEnv()->time() . "\n";
        close FILE;
        return $generated_index;
    }

    sub load {
        my $self = shift;
        my $id   = $_[0];
        if ($id) {
            $self->{'CONFIG'}->{'INDEX'} = $id;
            open FILE, "<" . $Init->getEnv()->tmp_dir() . "/" . $id . ".lock";
            my @FILE = <FILE>;
            close FILE;
            chomp(@FILE);
            foreach my $rigo (@FILE) {
                my ( $key, $value ) = split( /:/, $rigo );
                $self->{'CONFIG'}->{$key} = $value;
            }
            return $self;
        }
        else {
            $Init->io->warn("No id given");
        }
    }

    sub get_var() {
        my $self = shift;
        return $self->{'CONFIG'}->{ $_[0] };
    }

    sub daemon {
        my $self = shift;
        croak "You have not run start..\n"
            if !exists( $self->{'CONFIG'}->{'INDEX'} );
        my $this_pid = Unix::PID->new();
        my $p;
        my $cmd
            = $Init->getIO()->generate_command( $self->{'CONFIG'}->{'code'} );
        $Init->getIO()->debug($cmd);

        #$Init->getIO()->set_debug(1);
        my ( $wtr, $rdr, $err );
        use Symbol 'gensym';
        $err = gensym;

        if ( $p = open3( $wtr, $rdr, $err, $cmd ) ) {
            $self->save_pid($p);
            while (<$rdr>) {
                $self->save($_);

            }
            $self->save("Daemon mode\n");
            return 1;
        }
        else {
            $Init->getIO()
                ->print_error( "Error! $err " . $self->{'CONFIG'}->{'code'} );
            $self->destroy();
            return ();
        }

        #$Init->getIO()->set_debug(0);
    }



    sub save_pid {
        my $self = shift;
        my $FH;
        open $FH,
              ">"
            . $Init->getEnv()->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'INDEX'} . ".pid";
        print $FH $_[0];
        close $FH;
        $self->{'CONFIG'}->{'PID'} = $_[0];
    }

    sub save {
        my $self = shift;
        open FILE,
              ">>"
            . $Init->getEnv()->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'INDEX'} . ".out";
        print FILE $_[0];
        close FILE;
    }

    sub save_output() {
        my $self = shift;
        if ( $_[1] ) {
            open FILE,
                  ">"
                . $Init->getEnv()->tmp_dir() . "/"
                . $self->{'CONFIG'}->{'INDEX'} . ".out";
            print FILE @_;
            close FILE;
        }
        else {
            open FILE,
                  ">"
                . $Init->getEnv()->tmp_dir() . "/"
                . $self->{'CONFIG'}->{'INDEX'} . ".out";
            print FILE $_[0];
            close FILE;
        }
    }

    sub get_pid() {
        my $self = shift;
        if (open FILE,
            "<"
            . $Init->getEnv()->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'INDEX'} . ".pid"
            )
        {
            my @pid = <FILE>;
            close FILE;
            return $pid[0];
        }
        return ();

    }

    sub get_output_file() {
        my $self = shift;
        return
              $Init->getEnv()->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'INDEX'} . ".out";
    }

    sub get_output() {
        my $self = shift;
        if (  -e $Init->getEnv()->tmp_dir() . "/"
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
        }
        else {
            return 0;
        }
    }

    sub get_id() {
        my $self = shift;
        return $self->{'CONFIG'}->{'INDEX'};
    }

    sub output() {
        my $self = shift;
        if (  -e $Init->getEnv()->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'INDEX'}
            . ".out" )
        {
            open FILE,
                  "<"
                . $Init->getEnv()->tmp_dir() . "/"
                . $self->{'CONFIG'}->{'INDEX'} . ".out";
            return FILE;
        }
        else {
            return 0;
        }
    }

    sub remove_lock() {
        my $self = shift;
        unlink(   $Init->getEnv()->tmp_dir() . "/"
                . $self->{'CONFIG'}->{'INDEX'}
                . ".lock" );
    }

    sub setParam() {
        my $self  = shift;
        my $VAR   = $_[0];
        my $VALUE = $_[1];
        $self->{'CONFIG'}->{$VAR} = $VALUE;
    }

    sub set() {
        my $self = shift;
        %{ $self->{'CONFIG'} } = @_;
    }

    ## fork and pidof WILL BE REMOVED IN FUTURE VERSIONS 
    sub fork {
        my $self = shift;
        my $p;
        croak "You have not run start..\n"
            if !exists( $self->{'CONFIG'}->{'INDEX'} );
        if ( my $pid = fork ) {
            waitpid( $pid, 0 );
        }
        else {
            if (fork) {
                exit;
            }
            else {
                open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
                my $this_pid = Unix::PID->new();
                my $cmd      = $Init->getIO()
                    ->generate_command( $self->{'CONFIG'}->{'code'} );
                open( $handle, "$cmd |" )
                    or
                    $Init->debug( "Failed to open pipeline $!", __PACKAGE__ );
                if ( $p = $self->pidof($cmd) ) {
                    $self->save_pid($p);
                    while (<$handle>) {
                        $self->save($_);
                    }
                    $self->remove_lock();
                }
                else {
                    $Init->getIO()
                        ->print_alert("Can't get pid of the forked process");
                    $self->destroy();
                    close($handle);
                }
            }
            exit;
        }
    }

    sub pidof($) {
        my $self     = shift;
        my @PIECES   = split( /\s+/, shift );
        my $this_pid = Unix::PID->new();
        my $p;
        my %matr;
        my $current_time = $Init->getEnv()->time_pid();
        $Init->getIO()->debug( "getting the pid of: " . $PIECES[0] );
        my $I = 0
            ; #We set a variable to 0, to be the index for the array we are visiting

        foreach my $piece (@PIECES) {
            my @FOUND_PIDS = $this_pid->get_pidof($piece);
            my $first = 0;    #another index for the PIDS FOUND FOR THE PIECE
            foreach my $found_pid (@FOUND_PIDS) {
                my @PID_INFO = $this_pid->pid_info($found_pid);
                $matr{$found_pid}++ if ( $PID_INFO[8] eq $current_time );
                $matr{$found_pid}++ if ( $PID_INFO[9] =~ /0\:/ );

     #So, every pid it's important, but the first is the most among the others
     #Maybe i have to check the time of creation, will be better instead!
     #              $Init->getIO()->debug("$piece found $found_pid");
     #              if ( $matr{$found_pid} )
     #              {
     #                  $matr{$found_pid} -= $first;
     #              } else
     #              {
     #                  $matr{$found_pid} = $first;
     #              }
                $first++;
            }
            $I++;
        }
        my @SORTED_PIDS = sort { $matr{$b} <=> $matr{$a} } ( keys(%matr) );
        {
            $p = shift(@SORTED_PIDS);

            #$Init->getIO()->debug("popped $last_pid, shifted $first_pid");
        }    # end-foreach
        $Init->getIO()->debug( "MAX PID " . $p );
        return ($p);
    }
}
1;
__END__
