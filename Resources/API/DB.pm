package Resources::DB;

use Moose;
use KiokuDB;
use Search::GIN::Extract::Class;
use Search::GIN::Query::Manual;
use Search::GIN::Query::Class;
use Fcntl qw(:DEFAULT :flock);
use Resources::Models::Snap;
use Nemesis::Inject;

nemesis resource {
    my $Dispatcher = $Init->ml->loadmodule("Dispatcher");
    $self->Dispatcher($Dispatcher);
}

has 'BackEnd'    => ( is => "rw" );
has 'Dispatcher' => ( is => "rw" );

sub lookup() {
    my $self = shift;
    my $uuid = shift;
    return $self->BackEnd->lookup($uuid);
}

sub add () {
    my $self = shift;

    # create a scope
    # my $Obj = shift;
    my @Objs = @_;

    #my $s   = $self->BackEnd->new_scope;

    # takes a snapshot of $some_object
    $self->BackEnd->scoped_txn(
        sub {
            $self->BackEnd->insert(@Objs);
        }
    );
    foreach my $Obj (@Objs) {
        my ($ModuleName) = $Obj =~ /(.*?)\=/;

        #$Init->io->debug("Now dispatcher seek for event_ $ModuleName");
        $self->Dispatcher->match( "event_" . $ModuleName, $Obj )
            ;    #Not Async for now.

    }
    return @Objs;
}

sub update() {
    my $self = shift;
    my $Obj  = shift;
    my $s    = $self->BackEnd->new_scope;
    $self->BackEnd->txn_do(
        sub {
            $self->delete($Obj);
            $self->add($Obj);
        }
    );

    #   $self->BackEnd->txn_do( sub {$self->BackEnd->update($Obj);}  );

    return $Obj;

}

sub swap() {
    my $self      = shift;
    my $oldObject = shift;
    my $newObject = shift;
    my $s         = $self->BackEnd->new_scope;
    my $Snap = Resources::Snap->new( was => $oldObject, now => $newObject );
    $self->Init->getIO->debug( "Snap created at " . $Snap->date );
    $self->BackEnd->txn_do(
        sub {
            $self->delete($oldObject);
            $self->add($newObject);
            $self->add($Snap);
        }
    );
    return $newObject;
}

sub delete() {
    my $self = shift;
    my $Obj  = shift;
    my $s    = $self->BackEnd->new_scope;
    $self->BackEnd->txn_do( sub { $self->BackEnd->delete($Obj); } );
    return ();
}

sub connect() {
    my $self = shift;
    my $BackEnd;

    if ( @_ != 0 ) {
        $BackEnd = shift;
    }
    if ( defined($BackEnd) ) {
        $self->BackEnd($BackEnd);
        return $self;
    }
    else {
        # $BackEnd = KiokuDB->connect(

        #     ###DBD HANGS ON EXIT.
        #     ### DBI WOULD BE BETTER.
        #
        #     "bdb-gin:dir=" . $self->Init->getSession()->getSessionPath,
        #     create  => 1,
        #            # serializer => "yaml", # defaults to storable

        #    # log_auto_remove => 1,
        #    extract => Search::GIN::Extract::Class->new
        # ) or $Init->io->error("Error loading BackEnd");

        $BackEnd = KiokuDB->connect(
            "bdb-gin:dir=" . $self->Init->getSession()->getSessionPath,
            create       => 1,
            extract      => Search::GIN::Extract::Class->new,
            live_objects => {
                clear_leaks  => 1,
                leak_tracker => sub {
                    my @leaked = @_;

                    warn "leaked " . scalar(@leaked) . " objects";

                    # try to mop up.
                    use Data::Structure::Util qw(circular_off);
                    circular_off($_) for @leaked;
                    }
            }
        ) or $Init->io->error("ERROR $!");

        $self->BackEnd($BackEnd);
    }
    $Init->io->debug( "Connected", __PACKAGE__ );
    return $self;
}

sub list_obj() {
    my $self  = shift;
    my $scope = $self->BackEnd->new_scope();
    my $all   = $self->BackEnd->all_objects;
    while ( my $chunk = $all->next ) {
        for my $object (@$chunk) {
            $self->Init->getIO()->debug("Obj $object");
        }
    }
    return $all;
}

sub search() {
    my $self = shift;
    my %Search;

    if ( @_ != 0 ) {
        my $ref = shift;
        %Search = %{$ref};

    }
    else {
        return;
    }
    my $results;
    if ( $Search{'class'} ) {

        # create query
        my $query
            = Search::GIN::Query::Class->new( class => $Search{'class'}, );

        # get results
        $results = $self->BackEnd->search($query);
    }
    else {
        $results = $self->BackEnd->search( \%Search );
    }
    return $results;

    # results are Data::Stream::Bulk

    #      while( my $chunk = $results->next ){
    #          for my $author (@$chunk){
    #              ...
    #          }
    #      }

}

sub searchRegex() {
    my $self = shift;
    my %Search;

    if ( @_ != 0 ) {
        my $ref = shift;
        %Search = %{$ref};

    }
    else {
        return;
    }
    my @Result;
    if ( !exists( $Search{'class'} ) ) {
        $self->Init->getIO->print_alert("You must supply a class");
        return 0;
    }
    my $query = Search::GIN::Query::Class->new( class => $Search{'class'}, );

    # get results
    my $all = $self->BackEnd->search($query);

    delete $Search{'class'};

    while ( my $chunk = $all->next ) {
        for my $object (@$chunk) {

            foreach my $attribute ( sort( keys %Search ) ) {
                eval {
                    my $res = $object->$attribute;
                    if ( defined($res) && $res =~ /$Search{$attribute}/i ) {
                        push( @Result, $object );
                    }

                };

            }

            # $self->Init->getIO()->debug("Obj $object");
        }
    }

    return @Result;
}

1;
