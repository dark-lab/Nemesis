package Resources::Node;

use Net::IP;
use Moose::Util::TypeConstraints;
use Moose;
use KiokuDB::Util qw(set);

subtype 'port', as 'Int', where { $_ > 0 and $_ < 65000 }, message {"Ehmm"};

has 'ip'        => ( is => 'rw' );
has 'ports'     => ( is => 'rw', isa => "ArrayRef", default => sub { [] } );
has 'url'       => ( is => 'rw' );
has 'os'        => ( is => 'rw' );
has 'hostnames' => ( is => "rw" );
has 'attachments' => (
    does    => "KiokuDB::Set",
    is      => "rw",
    lazy    => 1,
    default => sub { set() }
);
has 'suspect' => ( is => 'rw' );

1;
