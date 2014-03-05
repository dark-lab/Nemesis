package Resources::API::DB;
use Nemesis::BaseRes -base;

use KiokuDB;                  #### XXX: to change database approach
use KiokuDB::Backend::DBI;    ## Just to ensure that will fail if not exist
use DBI;                      ## same here

#XXX: secretely planning to a DBM::Deep wrapper for no more tears on deps
use Search::GIN::Extract::Class;
use Search::GIN::Query::Manual;
use Search::GIN::Extract::Callback;
use Search::GIN::Extract::Multiplex;
use Search::GIN::Query::Class;
use Fcntl qw(:DEFAULT :flock);
use Resources::Models::Snap;

has 'BackEnd';
has 'Dispatcher';

sub prepare {
    my $self       = shift;
    my $Dispatcher = $self->Init->ml->loadmodule("Dispatcher");
    $self->Dispatcher($Dispatcher);
}

sub lookup {
    my $self = shift;
    my $uuid = shift;
    return $self->BackEnd->lookup($uuid);
}

sub add {
    my $self = shift;

    # create a scope
    # my $Obj = shift;
    my @Objs = @_;

    my $s = $self->BackEnd->new_scope;

    # takes a snapshot of $some_object
    $self->BackEnd->txn_do(
        sub {
            $self->BackEnd->store(@Objs);
        }
    );
    foreach my $Obj (@Objs) {
        my ($ModuleName) = $Obj =~ /(.*?)\=/;

        #$self->Init->io->debug("Now dispatcher seek for event_ $ModuleName");
        $self->Dispatcher->match( "event_" . $ModuleName, $Obj )
            ;    #Not Async for now.

    }
    return @Objs;
}

sub update {
    my $self = shift;
    my $Obj  = shift;
    my $s    = $self->BackEnd->new_scope;
    $self->BackEnd->txn_do(
        sub {
            $self->delete($Obj);
            $self->store($Obj);
        }
    );

    #   $self->BackEnd->txn_do( sub {$self->BackEnd->update($Obj);}  );

    return $Obj;

}

sub swap {
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

sub delete {
    my $self = shift;
    my $Obj  = shift;
    my $s    = $self->BackEnd->new_scope;
    $self->BackEnd->txn_do( sub { $self->BackEnd->delete($Obj); } );
    return ();
}

sub connect {
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
        # ) or $self->Init->io->error("Error loading BackEnd");

        $BackEnd = KiokuDB->connect(
            "dbi:SQLite:dbname="
                . $self->Init->getSession()->getSessionPath
                . "/.sqlite.db",
            create  => 1,
            extract => Search::GIN::Extract::Multiplex->new(
                extractors => [
                    Search::GIN::Extract::Class->new,    ## Extract class
                    Search::GIN::Extract::Callback->new(
                        extract => sub {
                            my ( $obj, $extractor, @args ) = @_;
                            return $obj->extract_index( $extractor, @args )
                                if $obj->does('Resources::API::GINIndexing')
                                ;                        ## Indexing Role
                            return;
                        },
                    ),

                ],
            ),
            clear_leaks  => 1,
            transactions => 1,
            leak_tracker => sub {
                my @leaked = @_;
                $self->Init->io->alert(
                    "leaked " . scalar(@leaked) . " objects, mop up" );

                # try to mop up.
                use Data::Structure::Util qw(circular_off);
                circular_off($_) for @leaked;
            },
        ) or $self->Init->io->error("ERROR $!");

        $self->BackEnd($BackEnd);
    }
    $self->Init->io->debug( "Connected", __PACKAGE__ )
        if defined $self->BackEnd;
    return $self;
}

sub list_obj {
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

sub search {
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
            = Search::GIN::Query::Class->new( class => $Search{'class'} );

        # get results
        eval { $results = $self->BackEnd->search($query); };
        if ($@) {
            $self->Init->io->debug("error on search of DB: $@");
            return undef;
        }
    }
    else {
        eval {
            my $query
                = Search::GIN::Query::Manual->new( values => \%Search, );
            $results = $self->BackEnd->search($query);
        };
        if ($@) {
            $self->Init->io->debug("error on search of DB: $@");

            return undef;
        }
    }
    return $results;

    # results are Data::Stream::Bulk

    #      while( my $chunk = $results->next ){
    #          for my $author (@$chunk){
    #              ...
    #          }
    #      }

}

sub searchRegex {
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
    my $query = Search::GIN::Query::Class->new( class => $Search{'class'} );

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
