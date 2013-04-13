use MooseX::Declare;
use Nemesis::Inject;
class Plugin::Scanner {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Scanner plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test nmap);

    has 'Arguments' => (
                            is=>"rw",
                            default=>"-sS -sV -O -A -P0", 
                            documentation => "Nmap arguments"
                        );
    has 'DB' =>( is=> "rw",
                 documentation=>"Database ");

    nemesis_moosex_module;
    use HTTP::Request;
    use Net::IP;
    use Nmap::Parser;
    use Resources::Node;
    use DateTime;

    method prepare(){
        $self->DB($self->Init->getModuleLoader->loadmodule("DB")->connect());
    }
    method test($SearchString,$Exploit) {
        my $Crawler=$self->Init->getModuleLoader()->loadmodule("Crawler");
        $Crawler->search($SearchString);
        $Crawler->fetchNext();
        my $LFI=$self->Init->getModuleLoader()->loadmodule("LFI");
        $LFI->Bug($Exploit);#Can be post or otherwise, so should implement the api with HTTP::Request object.
        $LFI->Crawler($Crawler);
        $LFI->test();
   }
   method nmap($Ip?){
    if($Ip) {
        $self->nmapscan($Ip);
    } else {
        my @Ips = $self->Init->getInterfaces()->ips();
        use NetAddr::IP;
        foreach my $Ip(@Ips){
            $self->Init->getIO()->print_info("Scanning the network of $Ip");
            $self->nmapscan($Ip.'/24');
        }
    }
   }


 

   method nmapscan($Ip){
    my $Np=Nmap::Parser->new();

    $Np->cache_scan($self->Init->getSession()->new_file(DateTime->now,__PACKAGE__));

    $self->Init->getIO()->print_info("Scanning started on $Ip");
    $Np->parsescan($self->Init->getEnv()->whereis("nmap"), $self->Arguments." $Ip");
    my $Session=$Np->get_session;
    $self->Init->getIO()->print_info("Session:".$Session->scan_args);
    foreach my $host($Np->all_hosts()){
        next if($host->status ne "up");
        my $results=$self->DB->search(ip => $host->addr);
        my $DBHost;
        while( my $chunk = $results->next ){
                     for my $foundhost (@$chunk){
                      $DBHost=$foundhost;
                      last;
                  }
        }
        my $Node=Resources::Node->new(
                ip => $host->addr
                );
        my $os         = $host->os_sig();
        $self->Init->getIO()->print_info($host->addr);
        $self->Init->getIO()->print_tabbed("Status: ".$host->status,3);
        $self->Init->getIO()->print_tabbed("HostNames: ".join(" ",$host->all_hostnames()),3);
        $Node->hostnames(join(" ",$host->all_hostnames()));
        $self->Init->getIO()->print_tabbed("Mac HW: ".$host->mac_addr(),3) if $host->mac_addr();
        if($os->name){
            $self->Init->getIO()->print_tabbed("OS Name: ".$os->name()." Family: ".$os->osfamily,3);
            $Node->os($os->osfamily);
        }
        my $Meta = $self->Init->getModuleLoader()->getInstance("metasploit");
        my @Found_Ports;
        for my $port ($host->tcp_ports()){
            my $service = $host->tcp_service($port);
                        push(@Found_Ports,$port."|".$service->name);

            $self->Init->getIO()->print_tabbed("===== ".$port." =====",3);
            $self->Init->getIO()->print_tabbed("Service Name: ".$service->name,4) if $service->name ;
            $self->Init->getIO()->print_tabbed("Service Version: ".$service->version,4) if $service->version;
            $self->Init->getIO()->print_tabbed("Confidence: ".$service->confidence,4) if $service->confidence;
        }
        $Node->ports(\@Found_Ports);
        $Node=$Meta->matchNode($Node);
        if(!defined($DBHost)){
            $self->DB->add($Node);
        } else {
            $self->DB->swap($DBHost,$Node);#This automatically generate a Resources::Snap db object to track the change
        }    
    }
   }


}
1;


