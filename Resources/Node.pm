use Net::IP;
use Moose::Util::TypeConstraints;
use MooseX::Declare;

  subtype 'port',
      as 'Int',
      where {$_ > 0 and  $_ < 65000},
      message { "Ehmm" };

class Resources::Node{

	has 'ip' => ( is=>'rw');
	has 'port' => (isa=>'port', is=>'rw');
  has 'url' => (is=>'rw');


}

