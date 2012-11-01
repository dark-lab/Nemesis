package Plugin::SessionHandler;
use warnings;
use Carp qw( croak );
use Nemesis::Session;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "SessionHandler Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS =
    qw(list save restore save_state restore_state list_state);    #NECESSARY

sub restore($) {
    my $self    = shift;
    my $env     = $self->{'core'}->{'env'};
    my $module  = $_[0];
    my $Session = new Nemesis::Session(
        ModuleLoader => $self->{'core'}->{'ModuleLoader'},
        env          => $env
    );
    $Session->restore($module);
    $self->{'core'}->{'ModuleLoader'}->{'modules'}
        ->{ $Session->{'modules'}->{$Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} }->{'Name'} } =
        $Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} );

#Sovrascrivo le referenze del moduleloader con quelle caricate in session, ritrovo il modulo tramite 'modules' -> MODULE_ID dentro la sessione
}

sub restore_state($) {
    my $self    = shift;
    my $env     = $self->{'core'}->{'env'};
    my $module  = $_[0];
    my $Session = new Nemesis::Session(
        ModuleLoader => $self->{'core'}->{'ModuleLoader'},
        env          => $env
    );
    $Session->restore($module);
    $self->{'core'}->{'ModuleLoader'} =
        $Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} );
}

sub save($) {
    my $self   = shift;
    my $env    = $self->{'core'}->{'env'};
    my $module = $_[0];
    my $Module;
    my $Session = new Nemesis::Session(        ModuleLoader => $self->{'core'}->{'ModuleLoader'},
        env          => $env);
    $Session->initialize($module);
    $self->{'core'}->{'ModuleLoader'}->{'modules'}->{$module}->info();
    $Session->{'CONF'}->{'VARS'}->{'MODULE_ID'}  =
        $Session->save_module($self->{'core'}->{'ModuleLoader'}->{'modules'}->{$module})
        ; #metto dentro la session MODULE ID l'id del salvataggio del modulo. (utilizzato per il restore)
    $self->{'core'}->{'IO'}->print_info(
        "Session ".$Session->{'CONF'}->{'VARS'}->{'MODULE_ID'}." saved with name: " . $Session->{'CONF'}->{'VARS'}->{'SESSION_NAME'}  );
 
    $Session->save();
}

sub save_state() {
    my $self = shift;
    my $env  = $self->{'core'}->{'env'};
    my $name = $_[0];
    my $Module;
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");
      
    $Session->initialize($name);
    ( $Module, $Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} ) =
        $Session->new_module('ModuleLoader')
        ; #metto dentro la session MODULE ID l'id del salvataggio del modulo. (utilizzato per il restore)
    $Module = $self->{'core'}->{'ModuleLoader'};
    $self->{'core'}->{'IO'}->print_info(
        "Session saved with name: " . $Session->{'CONF'}->{'VARS'}->{'SESSION_NAME'} );
    $Session->save();
}

sub list() {
    my $self    = shift;
    my $Session = new Nemesis::Session(
        ModuleLoader => $self->{'core'}->{'ModuleLoader'},
        env          => $self->{'core'}->{'env'}
    );

    my $session_dir =
          $self->{'core'}->{'env'}->workspace()."/"
        . $Session->{'CONF'}->{'VARS'}->{'SESSION_DIR'};

    opendir my $DH, $session_dir or croak "$0: opendir: $!";
    my @sessions = grep { -d "$session_dir/$_" && !/^\.{1,2}$/ } readdir($DH);
    $self->{'core'}->{'IO'}
        ->print_info( "Found a total of " . scalar(@sessions) . " sessions" );
    foreach my $session (@sessions) {
        $self->{'core'}->{'IO'}->print_tabbed($session,2);
    }

}

sub list_state() {
    my $self        = shift;
    
        my $Session = new Nemesis::Session;


    my $session_dir =
          $self->{'core'}->{'env'}->workspace()."/"
        . $Session->{'CONF'}->{'VARS'}->{'SESSION_DIR'};
    opendir my $DH, $session_dir
        or croak "$0: opendir: $!";
    my @sessions = grep { -d "$session_dir/$_" && !/^\.{1,2}$/ } readdir($DH);
    foreach my $session (@sessions) {
        if($Session->restore($session)){
            if ( $Session->is_state() ) {
                $self->{'core'}->{'IO'}->print_tabbed($session,2);
            }
        }
    }

}

sub new {    #NECESSARY
     #Usually new(), export_public_methods() and help() can be copyed from other plugins
    my $package = shift;
    bless( {}, $package );
    my (%Obj) = @_;
    %{ $package->{'core'} } = %Obj;

    #Here goes the required parameters to be passed

    croak("IO and environment must be defined\n")
        if ( !defined( $package->{'core'}->{'IO'} )
        || !defined( $package->{'core'}->{'env'} )
        || !defined( $package->{'core'}->{'interfaces'} ) );

    return $package;
}

sub export_public_methods() {    #NECESSARY
    my $self = shift;
    return @PUBLIC_FUNCTIONS;
}

sub help() {                     #NECESSARY
    my $self    = shift;
    my $IO      = $self->{'core'}->{'IO'};
    my $section = $_[0];
    $IO->print_title( $MODULE . " Helper" );
    if ( $section eq "configure" ) {
        $IO->print_title("nothing to configure here");
    }

}

sub clear() {                    #NECESSARY - CALLED ON EXIT
    1;
}

1;
__END__
