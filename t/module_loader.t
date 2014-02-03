use Test::Simple tests => 4;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->ml->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader initialization ' );

ok( defined($Init) && $Init->getModuleLoader->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader alias ' );

my @test=(1,2);

ok( &Nemesis::ModuleLoader::_match([1,2]  , 2 ) == 1,
    'Nemesis::ModuleLoader _match() ' );

ok( &Nemesis::ModuleLoader::_match(\@test  , 2 ) == 1,
    'Nemesis::ModuleLoader _match() ' );