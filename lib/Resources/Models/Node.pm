package Resources::Models::Node;

use Moose::Util::TypeConstraints;
use Moose;
use KiokuDB::Util qw(set);
with 'Resources::API::GINIndexing'
    ; 
subtype 'port', as 'Int', where { $_ > 0 and $_ < 65000 }, message {"Ehmm"};

has 'ip'        => ( is => 'rw' );
has 'ports'     => ( is => 'rw', isa => "ArrayRef", default => sub { [] } );
has 'url'       => ( is => 'rw' );
has 'os'        => ( is => 'rw' );
has 'hmac'      => ( is => "rw" );
has 'hostnames' => ( is => "rw" );
has 'attachments' => (
    does    => "KiokuDB::Set",
    is      => "rw",
    lazy    => 1,
    default => sub { set() }
);
has 'suspect'           => ( is => 'rw', default => 0 );
has 'nemesis_node'      => ( is => 'rw', default => 0 );
has 'nemesis_supernode' => ( is => 'rw', default => 0 );
sub extract_index {
    my $self = shift;
    return {
        ip => $self->ip
    };
}
1;
