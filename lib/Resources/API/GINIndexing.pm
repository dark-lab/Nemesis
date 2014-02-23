  package Resources::API::GINIndexing;
  use Moose::Role; # automatically turns on strict and warnings

  requires 'extract_index';   # Returns a hashref of index_name => index_value pairs for GIN
  1;