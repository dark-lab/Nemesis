package Plugin::metasploit;
use warnings;
use Carp qw( croak );
use Nemesis::Inject;
use Nemesis::Process;
require Data::MessagePack;
require LWP;
require HTTP::Request;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Metasploit Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions
my @PUBLIC_FUNCTIONS =
	qw(configure start call check_installation status where stop status_pids browser_autopwn)
	;    #NECESSARY
my $CONF = {
	VARS => { MSFRPCD_USER => 'spike',
			  MSFRPCD_PASS => 'spiketest',
			  MSFRPCD_PORT => 5553,
			  CLIENT       => LWP::UserAgent->new,
			  HOST         => '127.0.0.1',
			  MSFRPCD_API  => '/api/',
			  MESSAGEPACK  => Data::MessagePack->new()
	}
};
#nemesis_module;

nemesis_module {
	##This is run before the initialization of module.
#	$Init->getIO()->print_info("Testing ".__PACKAGE__." contructor"); #This won't work, $Init, it's not defined yet.
	print "Testing ".__PACKAGE__." Constructor\n"; #This will
	
	
}

sub prepare
{
	$Init->getIO()->print_info("Testing ".__PACKAGE__." prepare() function"); ##This is called after initialization of Init
}

sub call()
{
	my $self = shift;
	my $meth = shift;
	my @opts = @_;
	my $URL =
		  'http://'
		. $CONF->{'VARS'}->{'HOST'} . ":"
		. $CONF->{'VARS'}->{'MSFRPCD_PORT'}
		. $CONF->{'VARS'}->{'MSFRPCD_API'};
	if ( $meth ne 'auth.login' and !$self->{_authenticated} )
	{
		$self->msfrpc_login();
		unshift @opts, $self->{_token};
	} elsif ( $meth ne 'auth.login' )
	{
		unshift @opts, $self->{_token};
	}
	unshift @opts, $meth;
	my $req = new HTTP::Request( 'POST', $URL );
	$req->content_type('binary/message-pack');
	$req->content( $CONF->{'VARS'}->{'MESSAGEPACK'}->pack( \@opts ) );
	my $res = $CONF->{'VARS'}->{'CLIENT'}->request($req);
	$self->parse_result($res);
	croak( "MSFRPC: Could not connect to " . $URL )
		if $res->code == 500;
	croak("MSFRPC: Request failed ($meth)") if $res->code != 200;
	$Init->getIO()
		->debug_dumper(
					$CONF->{'VARS'}->{'MESSAGEPACK'}->unpack( $res->content ) );
	return $CONF->{'VARS'}->{'MESSAGEPACK'}->unpack( $res->content );
}

sub browser_autopwn()
{
	my $self = shift;
	@OPTIONS = ( "auxiliary",
				 "server/browser_autopwn",
				 {  LHOST   => "0.0.0.0",
					SRVPORT => "8080",
					URIPATH => "/"
				 }
	);
	$response = $self->call( "module.execute", @OPTIONS );
	if ( exists( $response->{'uuid'} ) )
	{
		$Init->getIO()
			->print_info(
			"Now you have to wait until browser_autopwn finishes loading exploits."
			);
		$self->parse_result($response);
		$Init->getIO()->print_tabbed( "Your URL : http://0.0.0.0:8080", 2 );
	} else
	{
		$Init->getIO()->print_error("Something went wrong");
	}
}

sub msfrpc_login()
{
	my $self = shift;
	my $user = $CONF->{'VARS'}->{'MSFRPCD_USER'};
	my $pass = $CONF->{'VARS'}->{'MSFRPCD_PASS'};
	my $ret  = $self->call( 'auth.login', $user, $pass );
	if ( $ret->{'result'} eq 'success' )
	{
		$self->{_token}         = $ret->{'token'};
		$self->{_authenticated} = 1;
	} else
	{
		$Init->getIO()->debug_dumper($ret);
		croak("MSFRPC: Authentication Failure");
	}
}

sub help()
{    #NECESSARY
	my $self    = shift;
	my $IO      = $self->{'core'}->{'IO'};
	my $section = $_[0];
	$IO->print_title( $MODULE . " Helper" );
	if ( $section eq "configure" )
	{
		$IO->print_title("nothing to configure here");
	}
}

sub start
{
	my $self  = shift;
	my $which = $_[0];
	my $Io    = $Init->getIO();
	if ( $which eq "stop" )
	{
		if ( exists( $self->{'process'}->{'msfrpcd'} ) )
		{
			$self->{'process'}->{'msfrpcd'}->destroy();
			delete $self->{'process'}->{'msfrpcd'};
		} else
		{
			$Io->print_alert("Process already stopped");
		}
	} else
	{
		my $code =
			  'msfrpcd -U '
			. $CONF->{'VARS'}->{'MSFRPCD_USER'} . ' -P '
			. $CONF->{'VARS'}->{'MSFRPCD_PASS'} . ' -p '
			. $CONF->{'VARS'}->{'MSFRPCD_PORT'} . ' -S';
		$Io->print_info("Starting msfrpcd service.");
		my $Process = $Init->getModuleLoader->loadmodule('Process');
		$Process->set( type => 'daemon',    # forked pipeline
					   code => $code,
					   Init => $Init,
		);
		$Process->start();
		$Io->debug( $Io->generate_command($code) );
		$self->{'process'}->{'msfrpcd'} = $Process;
		if ( $Process->is_running )
		{
			$Io->print_info("Service msfrcpd started");
			$Io->process_status($Process);
		}
	}
}

sub status
{
	my $self   = shift;
	my $output = $self->{'core'}->{'IO'};
	my $env    = $self->{'core'}->{'env'};
	my $process;
	foreach my $dev ( keys %{ $self->{'process'} } )
	{
		$self->service_status($service);
	}
}

sub service_status()
{
	my $self   = shift;
	my $dev    = $_[0];
	my $output = $self->{'core'}->{'IO'};
	my $env    = $self->{'core'}->{'env'};
	foreach my $service ( keys %{ $self->{'process'} } )
	{
		$output->process_status( $self->{'process'}->{$service} );
	}
}

sub stop
{
	my $self   = shift;
	my $output = $self->{'core'}->{'IO'};
	my $env    = $self->{'core'}->{'env'};
	my $dev    = $_[0];
	my $group  = $_[1];
	if ( !defined($dev) )
	{
		$output->print_alert("You must provide at least a device");
	} else
	{
		if ( defined($group) )
		{
			$output->print_info(
						 "Stopping all activities on " . $dev . " for $group" );
			my $process = $self->{'process'}->{$dev}->{$group};
			$process->destroy();
			delete $self->{'process'}->{$dev}->{$group};
		} else
		{
			foreach my $process ( keys %{ $self->{'process'}->{$dev} } )
			{
				$output->print_title( "Stopping $process on " . $dev . "" );
				$self->{'process'}->{$dev}->{$process}->destroy();
				delete $self->{'process'}->{$dev}->{$process};
			}
		}
		$output->exec("iptables -t nat -F");
	}
}

sub parse_result()
{
	my $self = shift;
	my $pack = $_[0];
	if ( exists( $pack->{'error'} ) )
	{
		$Init->getIO()
			->print_error("Something went wrong with your MSFRPC call");
		$Init->getIO()->print_error( "Code error: " . $pack->{'error_code'} );
		$Init->getIO()->print_error( "Message: " . $pack->{'error_message'} );
		foreach my $trace ( $pack->{'error_backtrace'} )
		{
			$Init->getIO()->print_tabbed( "Backtrace: " . $trace, 2 );
		}
	} else
	{
		if ( exists( $pack->{'job_id'} ) )
		{
			$Init->getIO()->print_info( "Job ID: " . $pack->{'job_id'} );
		}
	}
}
1;
__END__
