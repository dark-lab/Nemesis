use MooseX::Declare;


class Resources::DB {
	use Nemesis::Inject;
	use KiokuDB;
	nemesis_moosex_resource;

	has 'BackEnd' => (is="rw");

	  method add ($Obj){
            $self->BackEnd->txn_do(sub {
                $self->BackEnd->insert($Obj);
            });
            return $Obj;
      }

      method connect($BackEnd?){
      	if($BackEnd ){
      		$self->BackEnd($BackEnd);
      		return $self;
      	} else {
      		$BackEnd=KiokuDB->connect("bdb:dir=".$self->Init->getSession()->getSessionPath, create => 1);
      		$self->BackEnd($BackEnd);
      	}
      }

      method list_obj(){

      	my $all = $self->BackEnd->all_entries;
        while( my $chunk = $all->next ){
            entry: for my $id (@$chunk) {
                my $entry = $kioku->lookup($id->id);
              #  next entry unless blessed $entry && $entry->isa('DayDayUpX::Note');
              	$self->Init->getIO()->print_alert("Obj $entry");
              #  $entry->{id} = $id->id; # hack
            }
        }
      }


	}