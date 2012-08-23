package Nemesis::Process;
{
    use Carp qw( croak );
    use Unix::PID;

    sub new {

        my $package = shift;
        bless( {}, $package );
        %{ $package->{'CONFIG'} } = @_;
        if ( exists( $package->{'CONFIG'}->{'ID'} ) ) {
            $package->{'INDEX'} = $package->{'CONFIG'}->{'ID'};
            $package->load();
        }

        my $pid;
        my $output;

        croak "IO and environment must be defined\n"
            if ( !defined( $package->{'CONFIG'}->{'IO'} )
            || !defined( $package->{'CONFIG'}->{'env'} ) );
        return $package;
    }

    sub start {
        my $self = shift;
        $self->{'INDEX'} = $self->generate_lock()
            if !exists( $self->{'CONFIG'}->{'ID'} );
        if ( !defined( $self->{'CONFIG'}->{'type'} ) ) {
            croak "No type defined, aborting..";
        }
        else {
            if ( $self->{'CONFIG'}->{'type'} eq 'daemon' ) {
                $self->daemon();
            }
            else {
                $self->fork;
            }
        }
        $self->{'CONFIG'}->{'IO'}
            ->debug( "Starting ..  " . $self->{'CONFIG'}->{'code'} );
    }

    sub stop() {
        my $self = shift;

        kill 9 => $self->get_pid();
        kill( 9, $self->get_pid() );

        $self->destroy();
    }

    sub destroy() {

        my $self = shift;
        unlink(   $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'}
                . ".lock" );
        unlink(   $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'}
                . ".out" );
        unlink(   $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'}
                . ".pid" );

    }

    sub is_running() {
        my $self = shift;
        if ( !exists( $self->{'CONFIG'}->{'daemon'} ) ) {
            if (  -e $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'}
                . ".lock" )
            {
                return 1;
            }
            else {
                return 0;
            }
        }
        else {
            my $pid = Unix::PID->new();
            if ( $pid->is_pid_running( $self->get_pid() ) ) {
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
        while ( -e $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $generated_index
            . ".lock" )
        {
            $generated_index = int( rand() );
        }
        open FILE,
              ">"
            . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $generated_index . ".lock";
        foreach my $key ( sort( keys %{ $self->{'CONFIG'} } ) ) {
            next if $key eq "ID";
            next if $key eq "IO";
            next if $key eq "env";
            print FILE "$key:" . $self->{'CONFIG'}->{$key} . "\n";
        }
        print FILE "TIME:" . $self->{'CONFIG'}->{'env'}->time() . "\n";
        close FILE;
        return $generated_index;
    }

    sub load {
        my $self = shift;
        open FILE,
              "<"
            . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'CONFIG'}->{'ID'} . ".lock";
        my @FILE = <FILE>;
        close FILE;
        chomp(@FILE);
        foreach my $rigo (@FILE) {
            my ( $key, $value ) = split( /:/, $rigo );
            $self->{'CONFIG'}->{$key} = $value;
        }

    }

    sub get_var() {
        my $self = shift;
        return $self->{'CONFIG'}->{ $_[0] };
    }

    sub daemon {
        my $self = shift;
        croak "You have not run start..\n" if !exists( $self->{'INDEX'} );
        my $this_pid = Unix::PID->new();
        my $cmd =
            $self->{'CONFIG'}->{'IO'}
            ->generate_command( $self->{'CONFIG'}->{'code'} );
        system($cmd);
        $p = $this_pid->get_pidof($cmd);
        $self->save_pid($p);
        $self->save("Daemon mode");
    }

    sub fork {
        my $self = shift;
        croak "You have not run start..\n" if !exists( $self->{'INDEX'} );
        if ( my $pid = fork ) {
            waitpid( $pid, 0 );
        }
        else {

            if (fork) {

                exit;
            }
            else {

                my $this_pid = Unix::PID->new();
                my $cmd =
                    $self->{'CONFIG'}->{'IO'}
                    ->generate_command( $self->{'CONFIG'}->{'code'} );
                open( $handle, "$cmd  2>&1 |" )
                    or croak "Failed to open pipeline $!";
                $p = $this_pid->get_pidof( $self->{'CONFIG'}->{'code'} );
                $self->save_pid($p);
                while (<$handle>) {
                    $self->save($_);
                }
                $self->remove_lock();

            }
            exit;
        }

    }

    sub save_pid() {
        my $self = shift;
        open FILE,
              ">"
            . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'} . ".pid";
        print FILE $_[0];
        close FILE;
    }

    sub save() {
        my $self = shift;

        open FILE,
              ">>"
            . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'} . ".out";
        print FILE $_[0];
        close FILE;

    }

    sub save_output() {
        my $self = shift;
        if ( $_[1] ) {
            open FILE,
                  ">"
                . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'} . ".out";
            print FILE @_;
            close FILE;
        }
        else {
            open FILE,
                  ">"
                . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'} . ".out";
            print FILE $_[0];
            close FILE;
        }

    }

    sub get_pid() {
        my $self = shift;
        open FILE,
              "<"
            . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'} . ".pid";
        my @pid = <FILE>;
        close FILE;
        return "@pid";

    }

    sub get_output_file() {
        my $self = shift;
        return
              $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'} . ".out";

    }

    sub get_output() {
        my $self = shift;
        if (  -e $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'}
            . ".out" )
        {
            open FILE,
                  "<"
                . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'} . ".out";
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
        return $self->{'INDEX'};

    }

    sub output() {
        my $self = shift;
        if (  -e $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
            . $self->{'INDEX'}
            . ".out" )
        {
            open FILE,
                  "<"
                . $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'} . ".out";
            return FILE;
        }
        else {
            return 0;
        }

    }

    sub remove_lock() {
        my $self = shift;
        unlink(   $self->{'CONFIG'}->{'env'}->tmp_dir() . "/"
                . $self->{'INDEX'}
                . ".lock" );

    }

}

1;

__END__
