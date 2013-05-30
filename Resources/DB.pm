use MooseX::Declare;


class Resources::DB {
	use Nemesis::Inject;
	use KiokuDB;
      use Search::GIN::Extract::Class;
      use Search::GIN::Query::Manual;
      use Search::GIN::Query::Class;
                   use Resources::Snap;
  use Fcntl qw(:DEFAULT :flock);
	nemesis_resource;

	has 'BackEnd' => (is=>"rw");

  method lookup($uuid){
    return $self->BackEnd->lookup($uuid);
  }

	  method add ($Obj){

	  	# create a scope object
            my $s = $self->BackEnd->new_scope;
                         

             
            # takes a snapshot of $some_object
            $self->BackEnd->txn_do( 
                                  sub {
                                    $self->signalObj($Init->session->new_file(".ids"),$self->BackEnd->store($Obj),$Obj);
                                    }
                                  );
            return $Obj;
      }

      method signalObj($File,@PrintLine){
        my $printLine = join("||||",@PrintLine);
           open FH,">>$File";
            flock(FH, 1);   
            print FH $printLine."\n";
            close FH;
      }

      method update($Obj){
              my $s = $self->BackEnd->new_scope;
             $self->delete($Obj);
             $self->add($Obj);
   
           #   $self->BackEnd->txn_do( sub {$self->BackEnd->update($Obj);}  );

            return $Obj;

      }

      method swap($oldObject,$newObject){
             my $s = $self->BackEnd->new_scope;
             my $Snap=Resources::Snap->new(was=>$oldObject,now=>$newObject);
             $self->Init->getIO->debug("Snap created at ".$Snap->date);
             $self->delete($oldObject);
             $self->add($newObject);
             $self->add($Snap);
            return $newObject;                  
      }

      method delete($Obj){
            my $s = $self->BackEnd->new_scope;
            $self->BackEnd->txn_do( sub {$self->BackEnd->delete($Obj);}  );     
            return ();
      }
      method connect($BackEnd?){
      	if($BackEnd ){
      		$self->BackEnd($BackEnd);
      		return $self;
      	} else {
      		$BackEnd=KiokuDB->connect(
                                      "bdb-gin:dir=".$self->Init->getSession()->getSessionPath, 
                                      create => 1,
                                      extract => Search::GIN::Extract::Class->new
                                    );
      		$self->BackEnd($BackEnd);
      	}
        return $self;
      }

      method list_obj(){
      	my $scope=$self->BackEnd->new_scope();
      	my $all = $self->BackEnd->all_objects;
        while( my $chunk = $all->next ){
            for my $object (@$chunk) {
            	$self->Init->getIO()->debug("Obj $object");
            }
        }
        return $all;
      }

      method search(%Search){
            my $results;
            if($Search{'class'}){
                # create query
                my $query = Search::GIN::Query::Class->new(
                    class => $Search{'class'},
                );
                # get results
                $results = $self->BackEnd->search($query);
            } else{
                $results = $self->BackEnd->search(\%Search);
            }
            return $results;

           # results are Data::Stream::Bulk

           #      while( my $chunk = $results->next ){
           #          for my $author (@$chunk){
           #              ...
           #          }
           #      }

      }


      method searchRegex(%Search){
        my @Result;
        if(!exists($Search{'class'})) { $self->Init->getIO->print_alert("You must supply"); return 0;}
            my $query = Search::GIN::Query::Class->new(
              class => $Search{'class'},
          );
          # get results
          my $all = $self->BackEnd->search($query);

          delete $Search{'class'};

        while( my $chunk = $all->next ){
            for my $object (@$chunk) {

                 foreach my $attribute ( sort( keys %Search ) ) {
                    eval { 
                      my $res= $object->$attribute;
                      if(defined($res) && $res=~/$Search{$attribute}/i){
                         push(@Result,$object);
                      }

                    };
                    
                }

             # $self->Init->getIO()->debug("Obj $object");
            }
        }

        return @Result;
      }

	}
