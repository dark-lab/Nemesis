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
#TODO: for my insanity.... i Have to use THAT: https://github.com/SpiderLabs/msfrpc/tree/master/Net-MSFRPC
# a look at https://github.com/SpiderLabs/msfrpc/blob/master/Net-MSFRPC/lib/Net/MSFRPC.pm
my @PUBLIC_FUNCTIONS =
	qw(configure msfrpcd_start msfrpc_call check_installation status where stop status_pids)
	;    #NECESSARY
my $CONF = { VARS => { MSFRPCD_USER => 'spike',
					   MSFRPCD_PASS => 'spiketest',
					   MSFRPCD_PORT => 5553,
					   CLIENT       => LWP::UserAgent->new,
					   HOST			=> '127.0.0.1',
					   MSFRPCD_API => '/api/',
					   MESSAGEPACK => Data::MessagePack->new()
			 }
};
nemesis_module;

sub msfrpc_call()
{
	my $self = shift;
	my $meth = shift;
	my @opts = @_;
	my $URL= 'http://'.$CONF->{'VARS'}->{'HOST'}.":".$CONF->{'VARS'}->{'MSFRPCD_PORT'}.$CONF->{'VARS'}->{'MSFRPCD_API'};
	if ( $meth ne 'auth.login' and !$self->{_authenticated} )
	{
		$self->msfrpc_login();
	} elsif ( $meth ne 'auth.login' )
	{
		unshift @opts, $self->{_token};
	}
	unshift @opts, $meth;
	my $req = new HTTP::Request( 'POST', $URL );
	$req->content_type('binary/message-pack');
	$req->content( $CONF->{'VARS'}->{'MESSAGEPACK'}->pack( \@opts ) );
	my $res = $CONF->{'VARS'}->{'CLIENT'}->request($req);
	croak( "MSFRPC: Could not connect to " . $URL )
		if $res->code == 500;
	croak("MSFRPC: Request failed ($meth)") if $res->code != 200;
	$Init->getIO()->debug_dumper($CONF->{'VARS'}->{'MESSAGEPACK'}->unpack( $res->content ));
	return $CONF->{'VARS'}->{'MESSAGEPACK'}->unpack( $res->content );
}

sub msfrpc_login()
{
	my $self = shift;
	my $user = $CONF->{'VARS'}->{'MSFRPCD_USER'};
	my $pass = $CONF->{'VARS'}->{'MSFRPCD_PASS'};
	my $ret  = $self->msfrpc_call( 'auth.login', $user, $pass );

	$Init->getIO()->debug_dumper($ret);
	if ( $ret->{'result'} eq 'success' )
	{
		$self->{_token}         = $ret->{'token'};
		$self->{_authenticated} = 1;
	} else
	{
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

sub clear()
{    #NECESSARY - CALLED ON EXIT
	1;
}

sub msfrpcd_start
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
		$Process->set( type => 'daemon',                       # forked pipeline
					   code => $code,
					   Init =>$Init,
					   	);
					   	$Process->start();
		$Io->debug($Io->generate_command($code));
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

sub info
{
	my $self = shift;
	my $IO   = $self->{'core'}->{'IO'};
	my $env  = $self->{'core'}->{'env'};

	# A small info about what the module does
	$IO->print_info("->\tDummy module v$VERSION ~ $AUTHOR ~ $INFO");
}

sub configure
{
	my $self = shift;

	#postgre pc_hba.conf
}
1;
__END__
