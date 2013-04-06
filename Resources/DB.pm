use MooseX::Declare;


class Resources::DB {
	use Nemesis::Inject;
	use KiokuDB;
	nemesis_moosex_resource;

	has 'BackEnd' => (is=>"rw");

	  method add ($Obj){

	  	# create a scope object
my $s = $self->BackEnd->new_scope;
 
 
# takes a snapshot of $some_object
my $uuid = $self->BackEnd->store($Obj);
 
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
      	my $scope=$self->BackEnd->new_scope();
      	my $all = $self->BackEnd->all_objects;
        while( my $chunk = $all->next ){
            for my $object (@$chunk) {

            	              	$self->Init->getIO()->print_alert("Obj $object");

      
            }
        }
      }


	}