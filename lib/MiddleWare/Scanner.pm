package MiddleWare::Scanner;

use Nemesis::BaseModule -base;

#use HTTP::Request; #use NetAddr::IP;
#use Net::IP;
use Resources::Models::Node;
use DateTime;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Scanner plugin";
our $INFO    = "<www.dark-lab.net>";

our @PUBLIC_FUNCTIONS = qw(webtest nmap);

has 'Arguments';
has 'DB';

#use namespace::autoclean;

sub prepare {
    my $self = shift;

    #  $self->DB( $self->Init->ml->atom("DB")->connect );
    $self->Arguments("-sS -sV -O -A -P0");
}

sub webtest() {
    my $self         = shift;
    my $SearchString = shift;
    my $Exploit      = shift;
    my $Crawler      = $self->Init->ml()->atom("Crawler");
    $Crawler->search($SearchString);
    $Crawler->fetchNext();
    my @TESTS = qw (LFI RFI RCE AFU SQLi);
    foreach my $test (@TESTS) {
        my $Test = $self->Init->ml->load($test);
        $Test->Bug($Exploit)
            ; #Can be post or otherwise, so should implement the api with HTTP::Request object.
        $Test->Crawler($Crawler);
        if ( $Test->test() ) {

            #return true, attack succeed
        }
        else {
            #false, no luck
        }
    }
}

sub nmap() {
    my $self = shift;
    my $Ip   = shift;

    if ( !$self->Init->ml->got_lib("Nmap::Parser") )
    {    #if true it will be loaded
        $self->Init->io->error("You don't seem to have Nmap::Parser");
        return 0;
    }

    if ($Ip) {
        $self->nmapscan($Ip);
    }
    else {
        my @Ips = $self->Init->getInterfaces()->ips();
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

    $self->Init->getIO()
        ->print_info( "Scanning started on $Ip with " . $self->Arguments );
    $Np->parsescan( $self->Init->getEnv()->whereis("nmap"),
        $self->Arguments . " $Ip" );
    my $Session = $Np->get_session;
    $self->Init->getIO()->print_info( "Session:" . $Session->scan_args );
    my $Meta = $self->Init->ml->getInstance("metasploit");
    foreach my $host ( $Np->all_hosts() ) {
        next if ( $host->status ne "up" );
        my $results = $self->Init->ml->getInstance("Database")
            ->search( { ip => $host->addr } );
        my $DBHost;
        if ($results) {
            while ( my $chunk = $results->next ) {
                for my $foundhost (@$chunk) {
                    $DBHost = $foundhost;
                    last;
                }
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
        $Node->hmac($host->mac_addr) and $self->Init->getIO()
            ->print_tabbed( "Mac HW: " . $host->mac_addr(), 3 )
            if $host->mac_addr();

        if ( $os->name ) {
            $self->Init->getIO()
                ->print_tabbed(
                "OS Name: " . $os->name() . " Family: " . $os->osfamily, 3 );
            $Node->os( $os->osfamily . " : " .$os->name );
        }
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
            $self->Init->ml->getInstance("Database")->add($Node);
        }
        else {
            $self->Init->ml->getInstance("Database")->swap( $DBHost, $Node )
                ; #This automatically generate a Resources::Snap db object to track the change
        }
    }
}

1;

