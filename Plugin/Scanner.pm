use MooseX::Declare;
use Nemesis::Inject;
class Plugin::Scanner {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Scanner plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test );

    nemesis_moosex_module;


    method test($String) {
        my $Crawler=$self->Init->getModuleLoader()->loadmodule("Crawler");
        $Crawler->search($String);
        $Crawler->fetchNext();


   }

}
1;


