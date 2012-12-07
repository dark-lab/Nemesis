package Plugin::session;
use warnings;
use Carp qw( croak );
use Nemesis::Session;
use Data::Dumper;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "SessionHandler Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS =
    qw(list save spawn);    #NECESSARY

sub restore($) {
    my $self    = shift;
    my $env     = $self->{'core'}->{'env'};
    my $module  = $_[0];
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");
    $Session->restore($module);
        $self->{'core'}->{'IO'}->debug("ModuleName:".$Session->{'CONF'}->{'VARS'}->{'MODULE_NAME'});

    $self->{'core'}->{'IO'}->debug(  "Moduli attuali:".  Dumper($self->{'core'}->{'ModuleLoader'}->{'modules'}));
    $self->{'core'}->{'ModuleLoader'}->{'modules'}
        -> {$Session->{'CONF'}->{'VARS'}->{'MODULE_NAME'}} =
        $Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} );
        $Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} )->status();
    $self->{'core'}->{'IO'}->debug(Dumper($Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} )->{'process'}->{'eth0'}->{'sniffer'}));
        $self->{'core'}->{'IO'}->debug(  "Moduli attuali:".  Dumper($self->{'core'}->{'ModuleLoader'}->{'modules'}));

#Sovrascrivo le referenze del moduleloader con quelle caricate in session, ritrovo il modulo tramite 'modules' -> MODULE_ID dentro la sessione
}

sub restore_state($) {
    my $self    = shift;
    my $env     = $self->{'core'}->{'env'};
    my $module  = $_[0];
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");

    $Session->restore($module);
    $self->{'core'}->{'ModuleLoader'} =
        $Session->get_module($Session->{'CONF'}->{'VARS'}->{'MODULE_ID'} );
}

sub save($) {
    my $self   = shift;
    my $env    = $self->{'core'}->{'env'};
    my $module = $_[0];
    my $Module;
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");

    $Session->initialize($module);
$Session->{'CONF'}->{'VARS'}->{'MODULE_NAME'} = $module;
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
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");


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
    
    my $Session = $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");


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

sub spawn(){
    my $self=shift;
    my $Session_Name=$_[0];
    $self->{'CONF'}->{'SESSION_NAME'}=$Session_Name;
    $self->{'core'}->{'Session'}= $self->{'core'}->{'ModuleLoader'}->loadmodule("Session");
    my $Session=$self->{'core'}->{'Session'};
    
    my $RealId;
    if($Session->exists($Session_Name)){
        $self->{'core'}->{'IO'}->print_info("A session \"$Session_Name\" already exists, retrieving it for you.");
        $Session->restore($Session_Name);
        $RealId=$Session_Name;
    } else {
          
       $RealId=$Session->initialize($Session_Name);
        if ($RealId ne $Session_Name){
            $self->{'core'}->{'IO'}->print_info("Session name already taken, that's the new generated: ".$RealId);
        }
    }
    
    $self->{'core'}->{'IO'}->set_session($RealId);
}

sub savespawned(){
    my $self=shift;
    $self->{'core'}->{'Session'}->save();
    }


sub clear() {                    #NECESSARY - CALLED ON EXIT
    1;
}

1;
__END__
