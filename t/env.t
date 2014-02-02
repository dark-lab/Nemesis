use Test::Simple tests => 1;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->getEnv->isa("Nemesis::Env"),
    'Nemesis::Env initialization ' );

