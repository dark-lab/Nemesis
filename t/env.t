use Test::Simple tests => 2;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->getEnv->isa("Nemesis::Env"),
    'Nemesis::Env initialization ' );

ok( $Init->getEnv->is_installed("perl") == 1, "Nemesis::Env is_installed()" );
