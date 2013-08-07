package MiddleWare::Database;



use Fcntl qw(:DEFAULT :flock);
use Nemesis::Inject;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Database Manager plugin";
our $INFO    = "<www.dark-lab.net>";
my @PUBLIC_FUNCTIONS = ( "start", "stop", "list", "search", "delete", "add" );



nemesis module {

    my $DB = $Init->ml->loadmodule("DB");
    $DB->connect();
    $self->DB($DB);
    $self->start();

}


got 'DB' => ( is => "rw" );
got 'Dispatcher' => (is => "rw");

sub search(){
    my $self=shift;

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
    ######      Saving new ids on a file
    my $self = shift;
    while ( sleep 1 ) {
        my $WriteFile = $Init->session->new_file(".ids");
        my @Content;
        if ( -e $WriteFile ) {
            if ( open( FH, "< " . $WriteFile ) ) {
                if ( flock( FH, 1 ) ) {
                    @Content = <FH>;
                    chomp(@Content);
                    close FH;
                    open( FH, "> " . $WriteFile );
                    flock( FH, 1 );#Flock!
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

sub AUTOLOAD {
    my $self = shift or return undef;

    # Get the called method name and trim off the fully-qualified part
    ( my $method = $AUTOLOAD ) =~ s{.*::}{};



        ### Create a closure that will become the new accessor method
        my $alias = sub {
            my $closureSelf = shift;

            if ( @_ ) {
               return $closureSelf->$method(@_);
            }

            return undef;
        };

        # Assign the closure to the symbol table at the place where the real
        # method should be. We need to turn off strict refs, as we'll be mucking
            # with the symbol table.
      SYMBOL_TABLE_HACQUERY: {
            no strict qw{refs};
            *$AUTOLOAD = $alias;
        }

        # Turn the call back into a method call by sticking the self-reference
        # back onto the arglist
        unshift @_, $self;

        # Jump to the newly-created method with magic goto
        goto &$AUTOLOAD;
}


1;
