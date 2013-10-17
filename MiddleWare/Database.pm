package MiddleWare::Database;

use Fcntl qw(:DEFAULT :flock);
use Nemesis::BaseModule -base;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Database Manager plugin";
our $INFO    = "<www.dark-lab.net>";
my @PUBLIC_FUNCTIONS = qw( start stop list search delete add );

has 'DB'        ;
has 'Dispatcher';

sub prepare {
    my $self = shift;
  #  my $DB   = $self->Init->ml->loadmodule("DB");
   # $DB->connect();
  #  $self->DB($DB);
    $self->Dispatcher( $self->Init->ml->atom("Dispatcher") );
    $self->start();

}

sub search() {
    my $self = shift;
}

sub start() {
    my $self    = shift;
    my $Process = $self->Init->ml->loadmodule("Process");
    $Process->set(
        type     => "thread",
        instance => $self
    );

    #$Process->start;
}

sub run() {

    ############
    ######      Saving new ids on a file
    my $self = shift;
    while ( sleep 1 ) {
        my $WriteFile = $self->Init->session->new_file(".ids");
        my @Content;
        if ( -e $WriteFile ) {
            if ( open( FH, "< " . $WriteFile ) ) {
                if ( flock( FH, 1 ) ) {
                    @Content = <FH>;
                    chomp(@Content);
                    close FH;
                    open( FH, "> " . $WriteFile );

                    #flock( FH, 1 );#Flock!
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
