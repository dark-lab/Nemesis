package Resources::API::Trace;

use strict;
use warnings FATAL => 'all';
use B ();

my $trace_file;
my %initial_inc;

sub import {
  my (undef, $file, @extras) = @_;

  $trace_file = $file || '>>fatpacker.trace';
  # For filtering out our own deps later.
  # (Not strictly required as these are core only and won't have packlists, but 
  # looks neater.)
  %initial_inc = %INC;

  # Use any extra modules specified
  eval "use $_" for @extras;

  B::minus_c;
}

CHECK {
  return unless $trace_file; # not imported

  open my $trace, $trace_file
      or die "Couldn't open $trace_file to trace to: $!";

  for my $inc (keys %INC) {
    next if exists $initial_inc{$inc};
    print $trace "$inc\n";
  }
}

1;

__END__