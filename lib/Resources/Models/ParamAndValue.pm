package Resources::Models::ParamAndValue;

use Moose;

has 'SITE' => ( is => "rw" );   # site where this credential has been captured
has 'PARAMETER' => ( is => "rw" )
    ;    # parameter of the credential (maybe 'password')
has 'VALUE' => ( is => 'rw' )
    ;    # value of the credential (maybe the password sniffed)
 #has 'CREDENTIAL' => (is=>"rw", isa=>"ArrayRef", default => sub { [] }); # array of credential (parameter->value)

