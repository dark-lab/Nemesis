use Test::Simple tests => 1;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->ml->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader initialization ' );

