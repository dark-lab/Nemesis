package MiddleWare::session;
use Carp qw( croak );
use Data::Dumper;
use Nemesis::BaseModule -base;

my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = __PACKAGE__;
my $INFO    = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS =
    qw(list wrap spawn stash);    #Public exported functions NECESSARY

sub help() {                      #NECESSARY
    my $self    = shift;
    my $IO      = $self->Init->getIO();
    my $section = $_[0];
    $IO->print_title( $MODULE . " Helper" );
    if ( $section eq "list" ) {
        $IO->print_info("Lists the avaible(s) sessions");
    }
    if ( $section eq "wrap" ) {
        $IO->print_info("Import the flow of your session");
    }
    if ( $section eq "spawn" ) {
        $IO->print_info(
            "Create a new session or restore one (if it already exists)");
    }
    if ( $section eq "stash" ) {
        $IO->print_info("Give your session to the dogs");
    }
}

sub spawn() {
    my $self         = shift;
    my $Session_Name = $_[0];
    my $Session      = $self->Init->getSession();
    my $RealId;
    if ( $Session->exists($Session_Name) ) {
        $self->Init->getIO()
            ->print_info(
            "A session \"$Session_Name\" already exists, retrieving it for you."
            );
        $Session->restore($Session_Name);
        $RealId = $Session_Name;
    }
    else {
        $RealId = $Session->initialize($Session_Name);
        $Session->restore($Session_Name);
    }
}

sub list() {
    my $self    = shift;
    my $Session = $self->Init->getSession();
    my $session_dir =
          $self->Init->getEnv()->workspace() . "/"
        . $Session->getSessionDir;
    opendir my $DH, $session_dir or croak "$0: opendir: $!";
    my @sessions = grep { -d "$session_dir/$_" && !/^\.{1,2}$/ } readdir($DH);
    $self->Init->getIO()
        ->print_info( "Found a total of " . scalar(@sessions) . " sessions" );
    foreach my $session (@sessions) {
        $self->Init->getIO()->print_tabbed( $session, 2 );
    }
}

sub wrap {
    my $self = shift;
    $self->Init->getIO->print_info("Rolling back to your work session!");
    $self->Init->getSession()->wrap();
}

sub stash {
    my $self = shift;
    $self->Init->getIO()->print_info("Giving your session to the dogs");
    $self->Init->getSession()->stash();
    $self->Init->ml->execute_on_all("prepare");
}

1;
