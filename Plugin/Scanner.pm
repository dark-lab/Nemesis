use MooseX::Declare;
use Nemesis::Inject;
class Plugin::Scanner {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Scanner plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test nmap);

    has 'Arguments' => (is=>"rw",default=>"-sS -sV -O -A -P0", documentation=> "Nmap arguments");
    has 'DB' =>(is=> "rw" );

    nemesis_moosex_module;
    use HTTP::Request;
    use Net::IP;
    use Nmap::Parser;
    use Resources::Node;


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
                      $self->DB->delete($foundhost);
                      last;
                  }
        }
        if(!defined($DBHost)){
            $DBHost=Resources::Node->new(
                ip => $host->addr
                );
        }
        my $os         = $host->os_sig();
        $self->Init->getIO()->print_info($host->addr);
        $self->Init->getIO()->print_tabbed("Status: ".$host->status,3);
        $self->Init->getIO()->print_tabbed("HostNames: ".join(" ",$host->all_hostnames()),3);
        $self->Init->getIO()->print_tabbed("Mac HW: ".$host->mac_addr(),3) if $host->mac_addr();
        $self->Init->getIO()->print_tabbed("OS Name: ".$os->name(),3) if($os->name);
        my $Meta = $self->Init->getModuleLoader()->getInstance("metasploit");
        my @Found_Ports ;
        for my $port ($host->tcp_ports()){
            push(@Found_Ports,$port);
            my $service = $host->tcp_service($port);
            $self->Init->getIO()->print_tabbed($port.": ".$service->name." ".$service->version."(".$service->confidence().")",3);
            foreach my $expl (($Meta->matchExpl($service->name),$Meta->matchPort($port))){
                $DBHost->attachments->insert($expl);
            }
        }
        $DBHost->ports(\@Found_Ports);
        $self->DB->add($DBHost);
       
    }
   }


}
1;


