package MiddleWare::Database;

use Moose;
use Nemesis::Inject;
use Fcntl qw(:DEFAULT :flock);
############################################
our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Database Manager plugin";
our $INFO    = "<www.dark-lab.net>";
############################################
############################################
############################################
my @PUBLIC_FUNCTIONS = ( "start", "stop", "list", "search", "delete", "add" );
############################################
############################################
############################################

############################################
############################################
nemesis_module;


has 'DB'         => ( is => "rw" );

sub prepare() {
    my $self       = shift;

    my $DB = $self->Init->ml->loadmodule("DB");
    $DB->connect();
    $self->DB($DB);
   # $self->start();
}

sub start() {
    my $self    = shift;
    my $Process = $Init->ml->loadmodule("Process");
    $Process->set(
        type     => "thread",
        instance => $self
    );
#$Process->start;
}

sub run() {

  ############
  ######
    my $self = shift;
    while ( sleep 1 ) {
        my $WriteFile = $Init->session->new_file(".ids");
                my @Content;
      if(-e $WriteFile){
        if(open( FH, "< " . $WriteFile )){
         if (flock( FH, 1 )){
          @Content = <FH>;
          chomp(@Content);
          close FH;
          open( FH, "> " . $WriteFile );
          flock( FH, 1 );
          close FH;
          }
        }
      }
        foreach my $ID (@Content) {
            my @Info         = split( /\|\|\|\|/, $ID );
            my $uuid         = shift @Info;
            my $Name         = shift @Info;
            my ($ModuleName) = $Name =~ /(.*?)\=/;
            $ModuleName =~ s/\:\:/__/g;
            $self->Dispatcher->match( "event_" . $ModuleName,
                $self->DB->lookup($uuid) );
        }
    }
}


1;
