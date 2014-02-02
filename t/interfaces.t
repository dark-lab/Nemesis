use Test::Simple tests => 1;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->interfaces->isa("Nemesis::Interfaces"),
    'Nemesis::Interfaces initialization ' );

