use Net::IP;
use Moose::Util::TypeConstraints;
use MooseX::Declare;

  subtype 'port',
      as 'Int',
      where {$_ > 0 and  $_ < 65000},
      message { "Ehmm" };

class Resources::Node{
use KiokuDB::Util qw(set);
	has 'ip' => ( is=>'rw');
	has 'ports' => (is=>'rw',isa=>"ArrayRef[port]" ,default=> sub{ [] });
  has 'url' => (is=>'rw');

  has 'attachments' => (   does     => "KiokuDB::Set",
    is      => "rw",
    lazy    => 1,
    default => sub { set() } )  ;


}

1;