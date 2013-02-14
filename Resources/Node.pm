package Resources::Node;
use Net::IP;
use Moose::Util::TypeConstraints;
use MooseX::DeclareX;

  subtype 'port',
      as 'Int',
      where {$_ > 0 and  $_ < 65000},
      message { "Tua mama fa le pompe" };

class Resources::Node{

	has 'ip' => (isa=>'Net::IP', is=>'rw');
	has 'port' => (isa=>'ArrayRef[Resources::Port]', is=>'rw', default=>'spiketest');

	method call (Str $Command){

        ...

	}


}

class Resources::Port{
    has 'number' => (isa=>'port', is=>'rw');
    has 'state' => (isa=>'Int', is=>'rw');
    has 'associated_service' => (isa=>'Str', is=>'rw');

}