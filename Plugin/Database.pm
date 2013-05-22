

use MooseX::Declare;
    use Nemesis::Inject;

class Plugin::Database{
	

   use Fcntl qw(:DEFAULT :flock);



    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Database Manager plugin";


    our $INFO    = "<www.dark-lab.net>";
    our @PUBLIC_FUNCTIONS = ("start","stop","list","search","delete","add");

       nemesis_module;
        $SIG{'TERM'}=sub { threads->exit; };

       has 'Dispatcher'=> (is=>"rw");
       has 'DB'=> (is=>"rw");

       method prepare(){

          $self->Dispatcher($Init->ml->loadmodule("Dispatcher"));
          $self->DB($Init->ml->loadmodule("DB")->connect());

       }
       method search(){

       }

       method delete(){


       }

    method start(){
      my $Process=$Init->ml->loadmodule("Process");
      $Process->set(
          type=> "thread",
        instance=>$self
          );
      $Process->start;
    }
    method add(){

    }
    method list(){

    }
    method stop (){

    }
    method run(){
      while (sleep 1){
        my $WriteFile=$Init->session->new_file(".ids");
        open(FH, "< ".$WriteFile) ;
        flock(FH, 1);
        my @Content=<FH>;
        chomp(@Content);
        close FH;
        open(FH, "> ".$WriteFile) ;
        flock(FH, 1);
        close FH;
        foreach my $ID(@Content){
          my @Info=split(/\|\|\|\|/,$ID);
          my $uuid=shift @Info;
          my $Name=shift @Info;
          my ($ModuleName) = $Name=~/(.*?)\=/;
          $ModuleName=~s/\:\:/__/g;
          $self->Dispatcher->match("event_".$ModuleName,$self->DB->lookup($uuid));
        }
      }
    }



}