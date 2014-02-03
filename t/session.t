use Test::Simple tests => 2;
use Nemesis;
my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->getSession->isa("Nemesis::Session"),
    'Nemesis::Session initialization ' );

ok( $Init->getSession->serialize(" test ") eq "_test_",
    'Nemesis::Session serialize()' )
