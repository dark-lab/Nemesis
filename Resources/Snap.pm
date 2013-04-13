use MooseX::Declare;

class Resources::Snap{
		use DateTime;

		has 'was'  => (is=>"rw");
		has 'now'  => (is=>"rw");
		has 'date' => (is=>"rw" , default => sub { DateTime->now; })

		
}
1;