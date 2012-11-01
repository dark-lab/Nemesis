package Nemesis::Session;
{
    use Carp qw( croak );
    use Clone qw(clone);
    use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);
    use Data::Dumper;
    my $CONF = {
        VARS => { SESSION_DIR => "Sessions" }

    };

    sub new {

        my $package = shift;
        bless( {}, $package );
        %{ $package->{'core'} } = @_;
        if ( exists( $package->{'core'}->{'env'} ) ) {
            if ( !-d $package->{'core'}->{'env'}->workspace() . "/"
                . $CONF->{'VARS'}->{'SESSION_DIR'} )
            {
                mkdir(    $package->{'core'}->{'env'}->workspace() . "/"
                        . $CONF->{'VARS'}->{'SESSION_DIR'} );

            }
        }
        $package->{'CONF'}->{'VARS'}->{'SESSION_DIR'} =
            $CONF->{'VARS'}->{'SESSION_DIR'};

        return $package;
    }

    sub serialize() {
        my $self = shift;
        my $var  = $_[0];
        $var =~ s/\s+/_/g;

        return $var;
    }

    sub initialize($) {
        my $self         = shift;
        my $session_name = $self->serialize( $_[0] );
        my $session_dir;
        my $id;
        $session_dir =
              $self->{'core'}->{'env'}->workspace() . "/"
            . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
            . $session_name;

        if ( !-d $session_dir ) {
            mkdir($session_dir);
            $id = $session_name;
        }
        else {
            $id = $session_name . time;
            $session_dir =
                  $self->{'core'}->{'env'}->workspace() . "/"
                . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
                . $id;
            while ( -d $session_dir ) {

                $id = $session_name . time;
                $session_dir =
                      $self->{'core'}->{'env'}->workspace() . "/"
                    . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
                    . $id;

            }
            mkdir($session_dir);

        }

        $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'}          = $id;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'} = $session_dir;
        $session_dir =~ s/\s+/\\ /g;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} = $session_dir;

# A session can be used as a db, as a variable storage, and so on!
#Creates a session with a given name (id), so you can retrieve later your session
#Creates a dir for the session in the work directory.
#So you can list retrieve everything.
#Restore the state of the plugins and so on.
#
#A sessionhandler plugin is required
#Il sessionhandler, per salvare lo "stato " dei plugin in una giornata, salverà il tutto in una
#Session, e inserendoci dentro il moduleloader stesso ( e per il restore basta caricare la session corrispondente e sovrascrivere la referenza del loader).

    }

    sub is_state() {
        ##This is only to increase indexing speed
        my $self = shift;
        if ( $_[0] ) {
            $CONF{'VARS'}{'IS_STATE'} = $_[0];
        }
        else {
            return $CONF{'VARS'}{'IS_STATE'};
        }

    }

    sub new_file() {
        my $self = shift;
        my $name = $_[0];
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $name;
    }

    sub get_file() {
        my $self = shift;

        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $name = $_[0];
        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $name;
    }

    sub new_module($) {
        my $self = shift;

        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $module_name = $_[0];
        my $id          = int( rand(10000) );
        while ( exists( $self->{'modules'}->{$id} ) ) {
            $id = int( rand(10000) );
        }
        $self->{'modules'}->{$id}->{'Obj'} =
            $self->{'core'}->{'ModuleLoader'}->loadmodule($module_name);
        $self->{'modules'}->{$id}->{'Name'} = $module_name;
        return
            wantarray ? ( $self->{'modules'}->{$id}->{'Obj'}, $id ) : $module;

        #return $module;
    }

    sub save_module($) {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $module = shift;
        my $id     = int( rand(10000) );
        while ( exists( $self->{'modules'}->{$id} ) ) {
            $id = int( rand(10000) );
        }
        $module->info();
        $self->{'modules'}->{$id}->{'Obj'}  = clone($module);
        $self->{'modules'}->{$id}->{'Name'} = "saved";
        return $id;
    }

    sub get_module($) {
        my $self = shift;

        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $id = $_[0];
        return $self->{'modules'}->{$id}->{'Obj'};
    }

    sub save() {
        my $self = shift;

        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        use Data::Dumper;
        print Dumper( $self->{'modules'} );
        nstore( \$self,
            $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'}
                . "/.session" );
        nstore( \$self->{'CONF'},
            $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'}
                . "/.session.conf" );
        nstore( \$self->{'modules'},
            $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'}
                . "/.session.modules" );
        foreach my $key ( ( keys %{ $self->{'modules'} } ) ) {
            print Dumper( ( keys %{ $self->{'modules'}->{$key}->{'Obj'} } ) );
            nstore( \$self->{'modules'}->{$key}->{'Obj'},
                      $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'}
                    . "/.session.modules."
                    . $key );
            foreach
                my $key2 ( ( keys %{ $self->{'modules'}->{$key}->{'Obj'} } ) )
            {
                print Dumper($key2);
                nstore( \$self->{'modules'}->{$key}->{'Obj'}->{$key2},
                          $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'}
                        . "/.session.modules."
                        . $key . "."
                        . $key2 );
            }
        }

    }

    sub restore() {
        my $self    = shift;
        my $env     = new Nemesis::Env;
        my $session = $_[0];
        my $S_PATH =
              $env->workspace() . "/"
            . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
            . $session
            . "/";
opendir(DIR,$S_PATH);
my @FILES= readdir(DIR); 

        foreach my $f(@FILES){
            next if $f eq "." or if $f eq "..";
            
            if($f eq ".session"){
                $self = retrieve($S_PATH.$f);
                
            }
            $f=~s///g;
            if($f=~//){
                
            }
            
            
         print $f."\n"   ;
            
        }


        if ( -e $S_PATH ) {
          #  $self = retrieve($S_PATH);
        }
        else {
            return ();
        }
    }

}

1;

__END__
