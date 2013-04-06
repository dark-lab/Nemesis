use MooseX::Declare;
use Nemesis::Inject;
class Plugin::Scanner {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Scanner plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test nmap);

    nemesis_moosex_module;
    use HTTP::Request;
    use Net::IP;
    use Nmap::Parser;
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


    } else {
        my @Ips = $self->Init->getInterfaces()->ips();
        foreach my $Ip(@Ips){
                        my $NIP=Net::IP->new($Ip);

            $self->Init->getIO()->print_info("IP: ".$Ip."/24");
            $self->nmapscan($Ip."/24");


        }
    }




   }


 

   method nmapscan($Ip){
    my $Np=Nmap::Parser->new();
    $Np->parsescan($self->Init->getEnv()->whereis("nmap"), "-sS -sV -O -A -P0 $Ip");
        my $Session=$Np->get_session;

        $self->Init->getIO()->print_info("Session:".$Session->scan_args);

    foreach my $host($Np->all_hosts()){

        my $os         = $host->os_sig();

        $self->Init->getIO()->print_info($host->addr);
        $self->Init->getIO()->print_tabbed("Status: ".$host->status,3);
        $self->Init->getIO()->print_tabbed("HostNames: ".join(" ",$host->all_hostnames()),3);
        $self->Init->getIO()->print_tabbed("Mac HW: ".$host->mac_addr(),3);
           my $os_name = $os->name();
        $self->Init->getIO()->print_tabbed("OS Name: ".$os_name,3);

        for my $port ($host->tcp_ports()){
            my $service = $host->tcp_service($port);
            $self->Init->getIO()->print_tabbed($port.": ".$service->name." ".$service->product." ".$service->version."(".$service->confidence().")",3);
        }

    }

   }



}
1;


