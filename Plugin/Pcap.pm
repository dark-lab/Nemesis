package Plugin::Pcap;

#use warnings;
#use strict;
##use Net::TcpDumpLog;
#my $VERSION = '0.1a';
#my $AUTHOR  = "mudler";
#my $MODULE  = "Pcap analyzer Module";
#my $INFO    = "<www.dark-lab.net>";

##Public exported functions

#my @PUBLIC_FUNCTIONS = qw(configure start tail);    #NECESSARY

sub new {    #NECESSARY
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
sub clear() { 1; }

#sub export_public_methods() {    #NECESSARY
#my $self = shift;
#return @PUBLIC_FUNCTIONS;
#}

#sub help() {                     #NECESSARY
#my $self    = shift;
#my $IO      = $self->{'core'}->{'IO'};
#my $section = $_[0];
#$IO->print_title( $MODULE . " Helper" );
#if ( $section eq "configure" ) {
#$IO->print_title("Configure");
#$IO->print_info("FILE - absolute path of the file name to analyze");
#}

#}

#sub start {
##my $self = shift;
##my $IO   = $self->{'core'}->{'IO'};
##my $env  = $self->{'core'}->{'env'};

### Starting basis of the module

##my $log = Net::TcpDumpLog->new();
##$log->read("foo.pcap");

##foreach my $index ( $log->indexes ) {
##my ( $length_orig, $length_incl, $drops, $secs, $msecs ) =
##$log->header($index);
##my $data   = $log->data($index);
##my $EthObj = NetPacket::Ethernet->decode($data);
##my $IPObj  = NetPacket::IP->decode( $EthObj->{data} );

##foreach my $OneChange ( 0 .. $TotalChanges ) {
##if ( $IPField[$OneChange] ) {
##$IPObj->{ $IPField[$OneChange] } = $IPNewValue[$OneChange];
##}
##}

##if ( $IPObj->{proto} == 6 ) {    #TCP
##my $TCPObj  = NetPacket::TCP->decode( $IPObj->{data} );
##my $Payload = $TCPObj->{data};

##foreach my $OneChange ( 0 .. $TotalChanges ) {
##if ( $TCPField[$OneChange] ) {
##$TCPObj->{ $TCPField[$OneChange] } =
##$TCPNewValue[$OneChange];
##}
##}

##$TCPObj->{data} = $Payload;
##$IPObj->{data}  = $TCPObj->encode;
##}
##elsif ( $IPObj->{proto} == 17 ) {    #UDP
##my $UDPObj  = NetPacket::UDP->decode( $IPObj->{data} );
##my $Payload = $UDPObj->{data};

##foreach my $OneChange ( 0 .. $TotalChanges ) {
##if ( $UDPField[$OneChange] ) {
##$UDPObj->{ $UDPField[$OneChange] } =
##$UDPNewValue[$OneChange];
##}
##}

##$UDPObj->{data} = $Payload;
##$IPObj->{data}  = $UDPObj->encode;
##}
##elsif ( $IPObj->{proto} == 1 ) {    #ICMP
##my $ICMPObj = NetPacket::ICMP->decode( $IPObj->{data} );
##my $Payload = $ICMPObj->{data};

##foreach my $OneChange ( 0 .. $TotalChanges ) {
##if ( $ICMPField[$OneChange] ) {
##$ICMPObj->{ $ICMPField[$OneChange] } =
##$ICMPNewValue[$OneChange];
##}
##}

##$ICMPObj->{data} = $Payload;
##$IPObj->{data}   = $ICMPObj->encode;
##}
##else {    #Generic packets
###my $Payload = $IPObj->{data};
###
###foreach my $OneChange (0..$TotalChanges) {
###	if ($TCPField[$OneChange]) {
###		$TCPObj->{$TCPField[$OneChange]} = $TCPNewValue[$OneChange];
###	}
###}
###
###Reassemble
###$IPObj->{data} = $Payload;
##}

##if ($PcapOutputFile) {

###Lovely.  NetPacket won't reassemble Ethernet frames.
###We bindly hope this is actually ethernet, and just
###grab the 14 byte header from the original packet and
###prepend it to the new.
##my $NewPkt = substr( $Pkt, 0, 14 ) . $IPObj->encode;
##Net::Pcap::dump( $WriteHandle, $Hdr, $NewPkt );
##}
##else {
##die "Direct write unimplemented at the moment.\n";
##}
##}

#}

#sub tail {
##$file = File::Tail->new("/some/log/file");
##while ( defined( $line = $file->read ) ) {
##print "$line";
##}

#}

#sub where {
#my $self   = shift;
#my $output = $self->{'core'}->{'IO'};
#my $env    = $self->{'core'}->{'env'};

#my $path = $env->whereis( $_[0] );
#$output->print_info( $_[0] . " bin is at $path" );

#}

#sub info {
#my $self = shift;

#my $IO  = $self->{'core'}->{'IO'};
#my $env = $self->{'core'}->{'env'};

## A small info about what the module does
#$IO->print_info("->\tDummy module v$VERSION ~ $AUTHOR ~ $INFO");
#}

#sub configure {
#my $self  = shift;
#my $var   = $_[0];
#my $value = $_[1];
#$self->{'CONFIG'}->{$var} = $value;
#return;
#}

#sub Process {
#my $self = shift;
#my $IO   = $self->{'core'}->{'IO'};

#my $process = new Nemesis::Process(
#type => 'system',                   # forked pipeline
#code => join( ' ', @_ ),
#env  => $self->{'core'}->{'env'},
#IO   => $IO
#);
#$process->start();
#sleep 4;

#$IO->print_title(
#"Testing process module functions with " . join( ' ', @_ ) );
#$IO->print_info( "Is running: " . $process->is_running() );
#$IO->print_info( "associated pid : " . $process->get_pid() );
#while ( $process->is_running() == 1 ) {
#$IO->print_info("Waiting the process stop");
#sleep 1;
#}
#@output = $process->get_output();
#$process->destroy();
#print "@output" . "\n";

#}

#sub Use {
#my $self = shift;
#$self->{'core'}->{'IO'}
#->print_title("Test Module can access to loaded modules..");
#foreach my $module (
#sort( keys %{ $self->{'core'}->{'ModuleLoader'}->{'modules'} } ) )
#{
#$self->{'core'}->{'IO'}->debug($module);
#}
#$self->{'core'}->{'IO'}->print_info("");
#$self->{'core'}->{'IO'}->print_info("");

#$self->{'core'}->{'IO'}->print_info(
#"Also i can invoke functions to myself thru moduleLoader..\n\t Invoking help()"
#);

#$self->{'core'}->{'ModuleLoader'}->{'modules'}->{'Test_Module'}->help();
#}

#sub check_installation {
#my $self      = shift;
#my $env       = $self->{'core'}->{'env'};
#my $IO        = $self->{'core'}->{'IO'};
#my $workspace = $env->workspace();
#$IO->print_info( "Workspace: " . $workspace );
#}

1;

#__END__
