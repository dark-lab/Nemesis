use MooseX::Declare;

class Resources::Credential{
	

	has 'SITE' => (is=>"rw"); # site where this credential has been captured
	has 'PARAMAMETER' => (is=>"rw"); # parameter of the credential (maybe 'password')
	has 'VALUE' => (is=>'rw'); # value of the credential (maybe the password sniffed)

}