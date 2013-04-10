use MooseX::Declare;


class Resources::DB {
	use Nemesis::Inject;
	use KiokuDB;
      use Search::GIN::Extract::Class;
      use Search::GIN::Query::Manual;
      use Search::GIN::Query::Class;
	nemesis_moosex_resource;

	has 'BackEnd' => (is=>"rw");

	  method add ($Obj){

	  	# create a scope object
            my $s = $self->BackEnd->new_scope;
             
             
            # takes a snapshot of $some_object
            $self->BackEnd->txn_do( sub {$self->BackEnd->store($Obj);}  );
     
            return $Obj;
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
        if(!exists($Search{'class'}))) { $Init->getIO->print_alert("You must supply"); return 0;}
            my $query = Search::GIN::Query::Class->new(
              class => $Search{'class'},
          );
          # get results
          $results = $self->BackEnd->search($query);

          delete $Search{'class'};

        while( my $chunk = $all->next ){
            for my $object (@$chunk) {

                 foreach my $attribute ( sort( keys %Search ) ) {
                    if(eval { 
                      my $res= $Obj->$attribute;
                      return 1 if($res=~$Search{$attribute});
                      return 0;
                    }){
                      push(@Result,$Obj);
                    }
                }

              $self->Init->getIO()->debug("Obj $object");
            }
        }

        return @Result;
      }


	}