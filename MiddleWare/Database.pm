package MiddleWare::Database;

use Fcntl qw(:DEFAULT :flock);
use Nemesis::BaseModule -base;

our $VERSION          = '0.1a';
our $AUTHOR           = "mudler";
our $MODULE           = "Database Manager plugin";
our $INFO             = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw( start stop list find);

has 'Dispatcher';
has 'DB';

sub find() {
    ##It's just visual
    my $self = shift;
    my $arg  = shift;    #single argument for now
    if ( $arg =~ /exploit/i ) {

        my $results
            = $self->search( { class => "Resources::Models::Exploit" } );

#       while( my $block = $results->next ) {
#           foreach my $item ( @{$block} ) {
#               $self->Init->getIO->debug($item->ip.": ".join(",",@{$item->ports}),__PACKAGE__);
#               $self->Init->getIO->debug("Possible vulns ".$item->attachments->size);

        #           }
        #       }

        #Exploit visualization
    }
    elsif ( $arg =~ /node/i ) {
        my $results = $self->search( { class => "Resources::Models::Node" } );

        #Node visualization
        while ( my $block = $results->next ) {
            foreach my $item ( @{$block} ) {
                $self->Init->io->print_title( $item->ip );
                $self->Init->getIO->info( "Open ports: "
                        . join( ",", grep { s/\|.*$//g; } @{ $item->ports } )
                ) if @{ $item->ports } > 0;
                $self->Init->getIO->info(
                    "Possible vulns " . $item->attachments->size );

            }
        }

    }

}

sub add() {
    my $self  = shift;
    my @stuff = @_;
    my $DB    = $self->DB || $self->Init->ml->atom("DB");
    $DB->connect();
    return 1 if $DB->add(@stuff);
}

sub search () {
    my $self    = shift;
    my $Options = shift;
    my $DB      = $self->DB || $self->Init->ml->atom("DB");
    $DB->connect();
    return $DB->search($Options);
}

sub rsearch() {    #Regex search
    my $self    = shift;
    my $Options = shift;
    my $DB      = $self->DB || $self->Init->ml->atom("DB");
    $DB->connect();
    return $DB->searchRegex($Options);
}

sub remove() {
    my $self = shift;
    my $obj  = shift;
    my $DB   = $self->DB || $self->Init->ml->atom("DB");
    $DB->connect();
    return $DB->delete($obj);

}

sub update() {
    my $self   = shift;
    my $Object = shift;
    my $DB     = $self->DB || $self->Init->ml->atom("DB");
    $DB->connect();
    my $id  = $DB->object_to_id($Object);
    my $Old = $DB->lookup($id);
    return $DB->swap( $Old, $Object );

}

sub prepare {
    my $self = shift;

    #  my $DB   = $self->Init->ml->loadmodule("DB");
   # $DB->connect();
   # $self->DB($DB);
    $self->Dispatcher( $self->Init->ml->atom("Dispatcher") );
    $self->start();

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
