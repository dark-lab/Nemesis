package Nemesis::Session;
use File::Path;
{
    use Carp qw( croak );
    my $CONF = { VARS =>
            { SESSION_DIR => "Sessions", FLOWFILE => ".execution_flow" } };
    our $Init;

    sub new {
        my $package = shift;
        bless( {}, $package );
        %{$package} = @_;
        $Init = $package->{'Init'};

        if ( !-d $Init->getEnv()->workspace() . "/"
            . $CONF->{'VARS'}->{'SESSION_DIR'} )
        {
            mkdir(    $Init->getEnv()->workspace() . "/"
                    . $CONF->{'VARS'}->{'SESSION_DIR'} );
        }

        $package->{'CONF'}->{'VARS'}->{'SESSION_DIR'}
            = $CONF->{'VARS'}->{'SESSION_DIR'};
        return $package;
    }

    sub getSessionPath {
        my $self = shift;
        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'};
    }

    sub getSessionDir {
        my $self = shift;
        return $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'};
    }

    sub serialize {
        my $self = shift;
        my $var  = $_[0];
        $var =~ s/\s+/_/g;
        return $var;
    }

    sub info {
        $Init->getIO()->print_info("Session: a main module.");
    }

    sub new_file {
        my $self = shift;
        my $name = $_[0];

        my $Package = caller;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );

        if ($Package) {
            mkdir(
                $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $Package )
                if ( !-d $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
                . $Package );
            return
                  $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
                . $Package . "/"
                . $name;
        }

        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $name;
    }

    sub initialize {
        my $self         = shift;
        my $session_name = $self->serialize( $_[0] );
        my $session_dir;
        my $id;
        $session_dir
            = $Init->getEnv()->workspace() . "/"
            . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
            . $session_name;
        if ( !-d $session_dir ) {
            mkdir($session_dir);
            $id = $session_name;
        }
        else {
            $id = $session_name . time;
            $session_dir
                = $Init->getEnv()->workspace() . "/"
                . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
                . $id;
            while ( -d $session_dir ) {
                $id = $session_name . time;
                $session_dir
                    = $Init->getEnv()->workspace() . "/"
                    . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
                    . $id;
            }
            mkdir($session_dir);
        }
        $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'}          = $id;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'} = $session_dir;
        $session_dir =~ s/\s+/\\ /g;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} = $session_dir;
        return $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'};
    }

    sub exists() {
        my $self = shift;
        if ( $_[0] ) {
            return 1
                if ( -d $Init->getEnv()->workspace() . "/"
                . $CONF->{'VARS'}->{'SESSION_DIR'} . "/"
                . $_[0] );
            return 0;
        }
        else {
            return 1
                if ( exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
            return 0;
        }
    }

    sub getName {
        my $self = shift;
        return $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'};
    }

    sub execute_save {
        my $self    = shift;
        my $module  = shift @_;
        my $command = shift @_;
        my @ARGS    = @_;
        open my $COMMAND_LOG, ">>",
            $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
            . $CONF->{'VARS'}->{'FLOWFILE'};
        print $COMMAND_LOG $module . "\@"
            . $command . "\@"
            . join( '#', @ARGS ) . "\n";
        close $COMMAND_LOG;

        # Meglio un buffer?
    }

    sub restore() {
        my $self         = shift;
        my $session_name = $self->serialize( $_[0] );
        my $session_dir;
        my $id;
        $session_dir
            = $Init->getEnv()->workspace() . "/"
            . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
            . $session_name;
        croak "No Session found with that name!"  if ( !-d $session_dir ) ;
        $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'}          = $session_name;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH_STRIPPED'} = $session_dir;
        $session_dir =~ s/\s+/\\ /g;
        $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} = $session_dir;
        chdir( $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} );
        $Init->ml->execute_on_all("prepare");

    }

    sub safechdir() {
        my $self = shift;
        chdir( $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} );
    }

    sub safedir() {
        my $self = shift;
        my $dir  = shift;
        my $code = shift;
        chdir($dir);
        &$code;
        chdir( $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} );
    }

    sub wrap {
        my $self = shift;
        my $File = shift;
        my @FLOW;
        if ( defined($File) and ref($File) eq 'ARRAY' ) {
            @FLOW = @{$File};
        }
        elsif ( defined($File) ) {
            $Init->io->debug("taking from $File");
            if ( -e $File ) {
                @FLOW = @{ $self->_get_flow($File) };
            }
            else {
                $Init->io->error("$File does not exists");
            }
        }
        else {
            $Init->io->debug("defaulting to session");

            @FLOW = @{ $self->_get_flow() };

        }
        foreach my $FLOW_LINE (@FLOW) {
            chomp($FLOW_LINE);
            $Init->io->debug("My line is $FLOW_LINE");
            my @FLOW_PIECES = split( '@', $FLOW_LINE );
            my $module = shift(@FLOW_PIECES);
            next if !$module;
            my $method = shift(@FLOW_PIECES);
            next if !$method;
            my $ARGS = shift(@FLOW_PIECES);

            #next if !$ARGS;
            my @REAL_ARGS = split( '#', $ARGS ) if $ARGS;
            $Init->io->debug(
                " executing $module $method and " . join( " ", @REAL_ARGS ) );
            $Init->getModuleLoader()->execute( $module, $method, @REAL_ARGS );
        }
    }

    sub wrap_history() {    ##Only for cli. add history from a given term
        my $self = shift;
        my $term = $_[0];
        my @FLOW;

        #Method to wrap all!
        @FLOW = $self->_get_flow();
        foreach my $FLOW_LINE (@FLOW) {
            chomp($FLOW_LINE);
            my @FLOW_PIECES = split( '@', $FLOW_LINE );
            my $module = shift(@FLOW_PIECES);
            next if !$module;
            my $method = shift(@FLOW_PIECES);
            next if !$method;
            my $ARGS = shift(@FLOW_PIECES);
            next if !$ARGS;

            my @REAL_ARGS = split( '#', $ARGS );
            $term->addhistory(
                "$module\.$method " . join( " ", @REAL_ARGS ) );
        }

    }

    sub _get_flow() {
        my $self         = shift;
        my $File         = shift;
        my $ModuleLoader = $Init->getModuleLoader();
        my $IO           = $Init->getIO();
        my $COMMAND_LOG;
        my @FLOW;
        if ($File) {
            open $COMMAND_LOG, "<", $File
                or $Init->io->debug( "Cannot read flow "
                    . $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
                    . $File )
                and die
                ();
            @FLOW = <$COMMAND_LOG>;
        }
        else {
            open $COMMAND_LOG, "<",
                $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
                . $CONF->{'VARS'}->{'FLOWFILE'}
                or $Init->io->debug("Session is new, now flowfile")
                and return [];
            @FLOW = <$COMMAND_LOG>;
        }

        close $COMMAND_LOG;

        # @FLOW = $IO->unici(@FLOW);
        # shift(@FLOW);
        return \@FLOW;

    }

    sub stash {

        #Destroy!
        my $self = shift;
        if ($self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} eq "default_session" )
        {
            opendir( DIR, $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} );
            my @ANY = readdir(DIR);
            close DIR;
            foreach my $resource (@ANY) {
                unlink(   $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/"
                        . $resource );
            }
        }
        else {
            chdir("..");
            rmtree( $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} );
        }
        $self->restore("default_session");
    }

}
1;
__END__

sub is_state()
    {
        ##This is only to increase indexing speed
        my $self = shift;
        if ( $_[0] )
        {
            $CONF{'VARS'}{'IS_STATE'} = $_[0];
        } else
        {
            return $CONF{'VARS'}{'IS_STATE'};
        }
    }
    sub new_file()
    {
        my $self = shift;
        my $name = $_[0];
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $name;
    }

    sub get_file()
    {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $name = $_[0];
        return $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $name;
    }

    sub new_module($)
    {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $module_name = $_[0];
        my $id          = int( rand(10000) );
        while ( exists( $self->{'modules'}->{$id} ) )
        {
            $id = int( rand(10000) );
        }
        $self->{'modules'}->{$id} =
            $self->{'core'}->{'ModuleLoader'}->loadmodule($module_name);
        return wantarray
            ? ( $self->{'modules'}->{$id}, $id )
            : $self->{'modules'}->{$id};

        #return $module;
    }

    sub save_module
    {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        my $module = $_[0];
        my $id     = int( rand(10000) );
        while ( exists( $self->{'modules'}->{$id} ) )
        {
            $id = int( rand(10000) );
        }
        $module->info();
        $self->{'modules'}->{$id} = $module;
        return $id;
    }

    sub get_module
    {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        croak 'No id given' if ( !$_[0] );
        my $id = $_[0];
        return $self->{'modules'}->{$id};
    }

    sub remove_module
    {
        my $self = shift;
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        croak 'No id given' if ( !$_[0] );
        my $id = $_[0];
        delete( $self->{'modules'}->{$id} );
        return 1;
    }

    sub recursive_save()
    {
        my $self    = shift;
        my $modules = $_[0];
        my $name    = $_[1];
        foreach my $key ( keys %{$modules} )
        {

            #next if $dd->Seen($modules);
            next if $key eq "core";
            nstore( \$modules->{$key},
                    $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'}
                        . "/.session."
                        . $name . "."
                        . $key
            );

            #           my $my = ${
            #               retrieve(       $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'}
            #                             . "/.session."
            #                             . $name . "."
            #                             . $key
            #               )
            #               };
            #    $my->info();
            $self->recursive_save( $modules->{$key}, $name . "." . $key );
        }
    }

    sub restore()
    {
        my $self    = shift;
        my $env     = $self->{'core'}->{'env'};
        my $session = $_[0];
        my $S_PATH =
              $env->workspace() . "/"
            . $self->{'CONF'}->{'VARS'}->{'SESSION_DIR'} . "/"
            . $session . "/";
        opendir( DIR, $S_PATH );
        my @modules =
            grep {/^\./} readdir(DIR);    #solo quelli con il punto davanti.
        close DIR;
        print join( " ", @modules ) . "\n";
        $self->{'CONF'}    = ${ retrieve( $S_PATH . ".session.CONF" ) };
        $self->{'modules'} = ${ retrieve( $S_PATH . ".session.modules" ) };
        print "Restoring confs.\n";
        print Dumper( $self->{'CONF'} ) . "\n";
        print "Restoring modules.\n";
        print Dumper( $self->{'modules'} ) . "\n";

        foreach my $key ( keys %{ $self->{'modules'} } )
        {
            $self->{'modules'}->{$key} =
                ${
                retrieve(       $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'}
                              . "/.session.modules."
                              . $key
                )
                };
            $self->module_restore( $key, @modules );
            print "Key $key\n";
            print "finding for $key\n";
            $self->{'modules'}->{$key}->{'core'} =
                $self->{'core'};    #..... check?!
            $self->{'modules'}->{$key}->info();
        }
    }

    sub module_restore()
    {
        my $self      = shift;
        my $module    = shift;
        my @a_modules = @_;
        print "Module restore for $module\n";
        print "I moduli? sono questi @a_modules\n";

        #   print keys %{$self->{'modules'}->{$module}}."\n";
        foreach my $m ( sort { length $a <=> length $b } @a_modules )
        {   #In questo modo i moduli inner( i padri) dovrebbero uscire per primi
            print "File... " . $m . "\n";
            my @PIECES = split( /\./, $m );
            shift(@PIECES);    #i need this??! check please..
            if (     $PIECES[0]
                 and $PIECES[1]
                 and $PIECES[2]
                 and $PIECES[0] eq "session"
                 and $PIECES[1] eq "modules"
                 and $PIECES[2] eq $module )
            {    #controllo che sto visionando il modulo specificato
                print "FOUND!!!!!\n";
                my @nested = splice( @PIECES, 3 )
                    ;    #mi scorro come la referenza deve essere contenuta.
                print "Nested: " . join( "->", @nested ) . "\n";
                my $ref =
                    $self->{'modules'}->{$module};   #Inizialmente è a modules.
                print "Ref is " . Dumper($ref) . "\n";
                foreach my $g (@nested)
                {
                    $ref = $ref->{ $g
                        }; #LA scorro fino alla fine delle referenze (necessarie)
                    print "G is : "
                        . $g . "\n"
                        . "Ref is "
                        . Dumper($ref) . "\n";
                }
                my $newref = retrieve(
                       $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/" . $m );
                $ref = ${$newref};    #Eseguo il retrieve.
                print "Reference dumped.."
                    . Dumper($ref)
                    . " type "
                    . reftype( \$ref )
                    . "\n";
            }
        }
    }
}

    sub save()
    {
        my $self = shift;
        my $IO   = $self->{'core'}->{'IO'};
        $Data::Dumper::Purity   = 1;
        $Data::Dumper::Terse    = 1;
        $Data::Dumper::Deepcopy = 1;
        $IO->print_info("Called a session save");
        croak 'No name defined'
            if ( !exists( $self->{'CONF'}->{'VARS'}->{'SESSION_NAME'} ) );
        nstore( \$self->{'CONF'},
               $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/.session.CONF" );
        nstore( \$self->{'modules'},
            $self->{'CONF'}->{'VARS'}->{'SESSION_PATH'} . "/.session.modules" );

        $self->recursive_save( $self->{'modules'}, 'modules' );

    }
