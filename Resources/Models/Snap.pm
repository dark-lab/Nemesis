package Resources::Models::Snap;
use Moose;

use DateTime;

has 'was'  => ( is => "rw" );
has 'now'  => ( is => "rw" );
has 'date' => ( is => "rw", default => sub { DateTime->now; } );

1;
