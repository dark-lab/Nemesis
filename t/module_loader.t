use Test::Simple tests => 3;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->ml->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader initialization ' );

ok( defined($Init) && $Init->getModuleLoader->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader alias ' );

ok( $Init->getModuleLoader->_match( [1,2] , 2 ) == 1,
    'Nemesis::ModuleLoader _match() ' );

