package Resources::MSFRPC;
use MooseX::Declare;

class Resources::MSFRPC{

	has 'Username' => (isa=>'Str', is=>'rw', default=>'spike');
	has 'Password' => (isa=>'Str', is=>'rw', default=>'spiketest');
	has 'Host' => (isa=>'Str', is=>'rw', default=>'127.0.0.1');
	has 'Port' => (isa=>'Int', is=>'rw', default=>5553);
	has 'API' => (isa=>'Str', is=>'rw', default=>'/api/');

	method call (Str $Command){

    my @opts        = @_;
    my $UserAgent   = LWP::UserAgent->new;
    my $MessagePack = Data::MessagePack->new();
    $self->start()
        if ( !exists( $self->{'process'}->{'msfrpcd'} ) );
    my $URL =
          'http://'
        . $CONF->{'VARS'}->{'HOST'} . ":"
        . $CONF->{'VARS'}->{'MSFRPCD_PORT'}
        . $CONF->{'VARS'}->{'MSFRPCD_API'};
    if ( $meth ne 'auth.login' and !$self->{_authenticated} ) {
        $self->msfrpc_login();
    }
    unshift @opts, $self->{_token} if ( exists( $self->{_token} ) );
    unshift @opts, $meth;
    my $HttpRequest = new HTTP::Request( 'POST', $URL );
    $HttpRequest->content_type('binary/message-pack');
    $HttpRequest->content( $MessagePack->pack( \@opts ) );
    my $res = $UserAgent->request($HttpRequest);
    $self->parse_result($res);
    croak( "MSFRPC: Could not connect to " . $URL )
        if $res->code == 500;
    croak("MSFRPC: Request failed ($meth)") if $res->code != 200;
    $Init->getIO()->debug_dumper( $MessagePack->unpack( $res->content ) );
    return $MessagePack->unpack( $res->content );


	}


}