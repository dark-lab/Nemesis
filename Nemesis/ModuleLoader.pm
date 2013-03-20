package Nemesis::ModuleLoader;
{
    no warnings 'redefine';
   # use Try::Tiny;
   # use TryCatch;
    use LWP::Simple;
    use Regexp::Common qw /URI/;
    use The::Net;


    #external modules
    my @MODULES_PATH = ( 'Plugin', 'Resources' );

    our $Init;

    sub new {
        my $class = shift;
        my $self = { 'Base' => $base };
        %{$package} = @_;
        $Init = $package->{'Init'};
        $self->{'Base'}->{'pwd'} = $Init->getEnv()->{'ProgramPath'} . "/";
        return bless( $self, $class );
    }

    sub execute {
        my $self          = shift;
        my $module        = shift @_;
        my $command       = shift @_;
        my @ARGS          = @_;
        my $currentModule = $self->{'modules'}->{$module};
        eval {
            if ( eval { $currentModule->can($command);} ) {
                if ( $currentModule->$command(@ARGS) ) {
                    $Init->getSession()
                        ->execute_save( $module, $command, @ARGS )
                        if $module ne "session";
                }
            }
            else {
                $Init->getIO->debug("$module doesn't provide $command");
            }
        };
        if($@) {
            $Init->getIO->print_error(
                "Something went wrong calling the method '$command' on '$module': $@"
            );
        }
    }

    sub execute_on_all {
        my $self    = shift;
        my $met     = shift @_;
        my @command = @_;
        foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
            $self->execute( $module, $met, @command );
        }
    }

    sub export_public_methods() {
        my $self = shift;
        my @OUT;
        my @PUBLIC_FUNC;
        foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
            @PUBLIC_FUNC = ();
            eval {
                @PUBLIC_FUNC = eval {
                    $self->{'modules'}->{$module}->export_public_methods();
                };
                foreach my $method (@PUBLIC_FUNC) {
                    $method = $module . "." . $method;
                }
                push( @OUT, @PUBLIC_FUNC );
            };
            if($@) {
                $Init->getIO()->print_error(
                    "Error $@ raised when populating public methods");
            }
        }
        return @OUT;
    }

    sub listmodules {
        my $self = shift;
        my $IO   = $Init->getIO();
        $IO->print_title("List of modules");
        foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
            $IO->print_info("$module");
            $self->{'modules'}->{$module}->info();
        }
    }

    sub _findLibName{
        my $self=shift;
        my $URL=$_[0];
        my $Fetch = get($URL);
        while($Fetch=~/package\s+(.*?)\;/i){
            return $1;
        }

    }

    sub loadmodule() {
        my $self   = shift;
        my $module = $_[0];
        my %args = $_[1];
        my $IO     = $Init->getIO();
        my $object;
        if($module =~/$RE{URI}{HTTP}/) {
           require $module;
           $object=$self->_findLibName($module);
        }
        elsif ( my $Type = $self->_findLib($module) ) {
            $object = $Type . "::" . $module;
        }
        else {
            $object = "Nemesis::" . $module;
        }
        $Init->getIO()
            ->debug("loading plugin $object",__PACKAGE__  );
            eval("use $object");
            if($@){
                $Init->getIO()
                ->print_error("Something went wrong loading $object: $@");
                return ();
            }
        if(%args){
            eval {
                $object = $object->new( Init => $Init, %args );
            };
        } else {
            eval {
                $object = $object->new( Init => $Init );
            };
        }
        if($@) {
            $Init->getIO()
                ->print_error("Something went wrong loading $object: $@");
                return ();
        } 
        $object->prepare if ( eval { $object->can("prepare") } );
        $Init->getIO()->debug("Module $module correctly loaded",__PACKAGE__ );
        return $object;
    }

    sub getInstance(){
        my $self=shift;
        my $Instance=$_[0];
        return $self->{'modules'}->{$Instance} if(exists($self->{'modules'}->{$Instance}));
    }

    sub canModule(){
        my $self=shift;
        my $Can=$_[0];
        return @{$self->{'can'}->{$Can}} if(exists($self->{'can'}->{$Can}));
        foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
            my $Mod=$self->{'modules'}->{$module};
               if(eval{$Mod->can($Can);}){
                push(@{$self->{'can'}->{$Can}},$module);
               }
        }
        return @{$self->{'can'}->{$Can}};
    }

    sub _findLib() {
        my $self    = shift;
        my $LibName = $_[0];
        foreach my $Library (@MODULES_PATH) {
            foreach my $INCLib (@INC) {
                if ( -e $INCLib . "/" . $Library . "/" . $LibName . ".pm" ) {
                    return $Library;
                }
            }
            if (  -e $Init->getEnv()->getPathBin . "/" 
                . $Library . "/"
                . $LibName
                . ".pm" )
            {
                return $Library;
            }
        }
    }

    sub _findLibsByCategory() {
        my $self    = shift;
        my $LibName = $_[0];
        my @Result;
        foreach my $INCLib (@INC) {
            if ( -d $INCLib . "/" . $LibName ) {
                local *DIR;
                if ( opendir( DIR, $INCLib . "/" . $LibName ) ) {
                    @Result =
                        map { $_ = $LibName . "/" . $_; }
                        grep( !/^\.\.?$/, readdir(DIR) );
                    close DIR;
                    last;

                }

            }
            elsif ( -d $Init->getEnv()->getPathBin . "/" . $LibName ) {
                local *DIR;
                if (opendir( DIR, $Init->getEnv()->getPathBin . "/" . $LibName
                    )
                    )
                {
                    @Result =
                        map { $_ = $LibName . "/" . $_; }
                        grep( !/^\.\.?$/, readdir(DIR) );
                    close DIR;
                    last;

                }
            }
        }
        $Init->getIO()->debug( "FOUND " . join( " ", @Result ) );

        return @Result;

    }

    sub getLoadedLib() {
        my $self = shift;
        return @{ $self->{'LibraryList'} };
    }

    sub loadmodules {
        my $self = shift;
        my @modules;
        my $IO   = $Init->getIO();
        my @Libs = ();
        my $modules;
        my $mods = 0;
        foreach my $Library (@MODULES_PATH) {
            local *DIR;
            if ( !opendir( DIR, $Init->getEnv()->getPathBin . "/" . $Library )
                )
            {
                ##Se non riesco a vedere in locale, forse sono nell'INC?
                $IO->print_alert( "No "
                        . $Init->getEnv()->getPathBin . "/"
                        . $Library
                        . " detected to find modules" );
                foreach my $INCLib (@INC) {
                    if ( -d $INCLib . "/" . $Library ) {
                        #Oh, eccoli!
                        opendir( DIR, $INCLib . "/" . $Library );
                        push( @Libs,
                            map { $_ = $INCLib . "/" . $Library . "/" . $_ }
                            grep( !/^\.\.?$/, readdir(DIR) ) );
                        closedir(DIR);
                    }
                }
            }
            else {
                push(
                    @Libs,
                    map {
                        $_ =
                              $self->{'Base'}->{'pwd'} 
                            . $Library . "/"
                            . $_
                        }
                        grep( !/^\.\.?$/, readdir(DIR) )
                );
                closedir(DIR);
            }

        }

        foreach my $Library (@Libs) {
            my ($name) = $Library =~ m/([^\.|^\/]+)\.pm/;
           # $Init->getIO()
            #    ->debug( "detected Plugin/Resource $name in $Library",__PACKAGE__ );
            eval {
                if ( exists( $self->{'modules'}->{$name} ) ) {
                    delete $self->{'modules'}->{$name};
                }


               if ( $self->isModule($Library)) {

                    $Init->getIO()->debug( $Library . " is a module!",__PACKAGE__ );
                    $self->{'modules'}->{$name} = $self->loadmodule($name);
                    if ( exists( $self->{'modules'}->{$name} )  and $self->{'modules'}->{$name} ne "") {
                        $mods++;
                    }
       

                }
                elsif ($self->isResource($Library)) {
                    $Init->getIO()
                        ->debug("$name is a Nemesis Resource",__PACKAGE__ );
                }
                else {
                    $Init->getIO()
                        ->debug("$name it's nothing to me",__PACKAGE__ );
                }

            };
            if($@){
                $IO->print_error($@);
                    delete $self->{'modules'}->{$name};
                    next;
            }
        }
        $IO->print_info(
            "> $mods modules available. Double tab to see them\n");
        @{ $self->{'LibraryList'} } = @Libs;

        #delete $self->{'modules'};
        return 1;
    }

    sub isModule() {
        my $self   = shift;
        my $module = $_[0];
        open MODULE, "<" . $module
            or $Init->getIO()->print_alert("$module can't be opened");
        my @MOD = <MODULE>;
        close MODULE;
        foreach my $rigo (@MOD) {
            if ( $rigo
                =~ /(?<![#|#.*|.?#])(nemesis_module|nemesis_moose_module|nemesis_moosex_module)/
                )
            {
                return 1;
            }
        }
        return 0;
    }

    sub isResource() {
        my $self   = shift;
        my $module = $_[0];
        open MODULE, "<" . $module
            or $Init->getIO()->print_alert("$module can't be opened");
        my @MOD = <MODULE>;
        close MODULE;
        foreach my $rigo (@MOD) {
            if ( $rigo
                =~ /(?<![#|#.*|.?#])(nemesis_resource|nemesis_moose_resource|nemesis_moosex_resource)/
                )
            {
                return 1;
            }
        }
        return 0;
    }

}
1;
