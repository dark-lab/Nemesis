package Resources::MSFRPC;
use MooseX::DeclareX
    keywords => [qw(class)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];

class Resources::MSFRPC{

	has 'Username' => (isa=>'Str', is=>'rw', default=>'spike');
	has 'Password' => (isa=>'Str', is=>'rw', default=>'spiketest');
	has 'Host' => (isa=>'Str', is=>'rw', default=>'127.0.0.1');
	has 'Port' => (isa=>'Int', is=>'rw', default=>5553);
	has 'API' => (isa=>'Str', is=>'rw', default=>'/api/');
	


}