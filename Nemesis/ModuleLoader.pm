package Nemesis::ModuleLoader;

use TryCatch;

#external modules
my $base = { 'pwd' => './', };
my @MODULES_PATH = ( 'Plugin', 'Resources' );

our $Init;

sub new {
    my $class = shift;
    my $self = { 'Base' => $base };
    %{$package} = @_;
   # croak 'No init' if !exists( $package->{'Init'} );
    $Init = $package->{'Init'};
    $self->{'Base'}->{'pwd'} = $Init->getEnv()->{'ProgramPath'} . "/";
    return bless $self, $class;
}

sub execute {
    my $self          = shift;
    my $module        = shift @_;
    my $command       = shift @_;
    my @ARGS          = @_;
    my $currentModule = $self->{'modules'}->{$module};
    try {
        if ( UNIVERSAL::can( $currentModule, $command ) ) {
            $currentModule->$command(@ARGS);
            $Init->getSession()->execute_save( $module, $command, @ARGS )
                if $module ne "session";
        }
        else {
            $Init->getIO->debug("$module doesn't provide $command");
        }
    }
    catch($error) {
        $Init->getIO->print_error(
            "Something went wrong calling the method '$command' on '$module': $error"
        );
    };
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
        try {
            @PUBLIC_FUNC = eval {
                $self->{'modules'}->{$module}->export_public_methods();
            };
            foreach my $method (@PUBLIC_FUNC) {
                $method = $module . "." . $method;
            }
            push( @OUT, @PUBLIC_FUNC );
        }
        catch($error) {
            $Init->getIO()->print_error(
                "Error $error raised when populating public methods");
        };
    }
    return @OUT;
}

sub listmodules {
    my $self = shift;
    my $IO   = $Init->getIO();
    $IO->print_title("List of modules");
    foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
        $IO->print_info("$module");
        $self->{'modules'}->{$module}->info()
            ; #so i can call also configure() and another function to display avaible settings!
    }
}

sub loadmodule() {
    my $self   = shift;
    my $module = $_[0];
    my $IO     = $Init->getIO();
    my $object;
    if ( my $LibraryAbsPath = $self->_findLib($module) ) {
        $object = $LibraryAbsPath . "::" . $module;
    }
    else {
        $object = "Nemesis::" . $module;
    }
    $Init->getIO()->debug( "[" . __PACKAGE__ . "] : loading plugin $object" );
    try {
        $object = $object->new( Init => $Init );
    }
    catch($error) {
        $Init->getIO()
            ->print_error("Something went wrong loading $object: $error");
            return ();
    } 
    $object->prepare if ( eval { $object->can("prepare") } );
    $Init->getIO()->debug("Module $module correctly loaded");
    return $object;
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
            if (opendir( DIR, $Init->getEnv()->getPathBin . "/" . $LibName ) )
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
        if ( !opendir( DIR, $Init->getEnv()->getPathBin . "/" . $Library ) ) {
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
            push( @Libs,
                map { $_ = $self->{'Base'}->{'pwd'} . $Library . "/" . $_ }
                grep( !/^\.\.?$/, readdir(DIR) ) );
            closedir(DIR);
        }

    }

    foreach my $Library (@Libs) {
        my ($name) = $Library =~ m/([^\.|^\/]+)\.pm/;
        $Init->getIO()
            ->debug( "["
                . __PACKAGE__
                . "] : detected Plugin/Resource $name in $Library" );
        try {
            if ( exists( $self->{'modules'}->{$name} ) ) {
                delete $self->{'modules'}->{$name};
            }
             my $result = do($Library);
            if ( $self->isModule($Library) ) {
               

                $Init->getIO()->debug( $Library . " is a module!" );
                $self->{'modules'}->{$name} = $self->loadmodule($name);
                if ( exists( $self->{'modules'}->{$name} ) ) {
                    $mods++;
                }
                if ( !$result ) {
                    $Init->getIO()->print_error("$name didn't returned true");
                }
            }
            else {
                $Init->getIO()
                    ->print_alert("$name it's not a Nemesis module");
            }

        }
        catch($error) {
            $IO->print_error($error);
                delete $self->{'modules'}->{$name};
                next;
        };
    }
    $IO->print_info("> $mods modules available. Double tab to see them\n");
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
1;
