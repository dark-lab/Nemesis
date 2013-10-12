package MiddleWare::Scanner;

use Moose;
use Nemesis::Inject;
use HTTP::Request;
use Net::IP;
use Nmap::Parser;
use Resources::Models::Node;
use DateTime;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Scanner plugin";
our $INFO    = "<www.dark-lab.net>";

my @PUBLIC_FUNCTIONS = qw(test nmap);

has 'Arguments' => (
    is            => "rw",
    default       => "-sS -sV -O -A -P0",
    documentation => "Nmap arguments"
);
has 'DB' => (
    is            => "rw",
    documentation => "Database "
);

nemesis module { $self->DB( $Init->ml->load("DB")->connect );}


sub test() {
    my $self         = shift;
    my $SearchString = shift;
    my $Exploit      = shift;
    my $Crawler      = $self->Init->ml()->load("Crawler");
    $Crawler->search($SearchString);
    $Crawler->fetchNext();
    my @TESTS= qw (LFI RFI);
    foreach my $test(@TESTS){
        my $Test=$self->Init->ml->load($test);
        $Test->Bug($Exploit)
            ; #Can be post or otherwise, so should implement the api with HTTP::Request object.
        $Test->Crawler($Crawler);
        if($Test->test()){
            #return true, attack succeed
        } else {
            #false, no luck
        }
    }
}

sub nmap() {
    my $self = shift;
    my $Ip   = shift;
    if ($Ip) {
        $self->nmapscan($Ip);
    }
    else {
        my @Ips = $self->Init->getInterfaces()->ips();
        use NetAddr::IP;
        foreach my $Ip (@Ips) {
            $self->Init->getIO()->print_info("Scanning the network of $Ip");
            $self->nmapscan( $Ip . '/24' );
        }
    }
}

sub nmapscan() {
    my $self = shift;
    my $Ip   = shift;
    my $Np   = Nmap::Parser->new();

    $Np->cache_scan(
        $self->Init->getSession()->new_file( DateTime->now, __PACKAGE__ ) );

    $self->Init->getIO()->print_info("Scanning started on $Ip");
    $Np->parsescan( $self->Init->getEnv()->whereis("nmap"),
        $self->Arguments . " $Ip" );
    my $Session = $Np->get_session;
    $self->Init->getIO()->print_info( "Session:" . $Session->scan_args );
    foreach my $host ( $Np->all_hosts() ) {
        next if ( $host->status ne "up" );
        my $results = $self->DB->search( ip => $host->addr );
        my $DBHost;
        while ( my $chunk = $results->next ) {
            for my $foundhost (@$chunk) {
                $DBHost = $foundhost;
                last;
            }
        }
        my $Node = Resources::Models::Node->new( ip => $host->addr );
        my $os = $host->os_sig();
        $self->Init->getIO()->print_info( $host->addr );
        $self->Init->getIO()->print_tabbed( "Status: " . $host->status, 3 );
        $self->Init->getIO()
            ->print_tabbed(
            "HostNames: " . join( " ", $host->all_hostnames() ), 3 );
        $Node->hostnames( join( " ", $host->all_hostnames() ) );
        $self->Init->getIO()
            ->print_tabbed( "Mac HW: " . $host->mac_addr(), 3 )
            if $host->mac_addr();

        if ( $os->name ) {
            $self->Init->getIO()
                ->print_tabbed(
                "OS Name: " . $os->name() . " Family: " . $os->osfamily, 3 );
            $Node->os( $os->osfamily );
        }
        my $Meta = $self->Init->getModuleLoader()->getInstance("metasploit");
        my @Found_Ports;
        for my $port ( $host->tcp_ports() ) {
            my $service = $host->tcp_service($port);
            push( @Found_Ports, $port . "|" . $service->name );

            $self->Init->getIO()
                ->print_tabbed( "===== " . $port . " =====", 3 );
            $self->Init->getIO()
                ->print_tabbed( "Service Name: " . $service->name, 4 )
                if $service->name;
            $self->Init->getIO()
                ->print_tabbed( "Service Version: " . $service->version, 4 )
                if $service->version;
            $self->Init->getIO()
                ->print_tabbed( "Confidence: " . $service->confidence, 4 )
                if $service->confidence;
        }
        $Node->ports( \@Found_Ports );
        $Node = $Meta->matchNode($Node);
        if ( !defined($DBHost) ) {
            $self->DB->add($Node);
        }
        else {
            $self->DB->swap( $DBHost, $Node )
                ; #This automatically generate a Resources::Snap db object to track the change
        }
    }
}

1;

