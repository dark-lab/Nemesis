use Test::Simple tests => 6;
use Nemesis;
my $Init = new Nemesis::Init();

ok( $Init->getSession->initialize("test") ,
    'Nemesis::Session initialize()' );

ok( defined($Init) && $Init->getSession->isa("Nemesis::Session"),
    'Nemesis::Session initialization ' );

ok( $Init->getSession->serialize(" test ") eq "_test_",
    'Nemesis::Session serialize()' );

ok( $Init->getSession->info, 'Nemesis::Session info()' );

ok( $Init->getSession->getSessionDir eq "Sessions",
    'Nemesis::Session info()' );

ok( $Init->getSession->new_file(".test") =~ /Sessions/,
    'Nemesis::Session new_file()' );

