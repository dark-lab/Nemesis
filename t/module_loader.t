use Test::Simple tests => 3;
use Nemesis;
use Scalar::Util qw ( reftype );

my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->ml->isa("Nemesis::ModuleLoader"),
    'Nemesis::ModuleLoader initialization ' );


my @test = ( 1, 2 );

ok( &Nemesis::ModuleLoader::_match( [ 1, 2 ], 2 ) == 1,
    'Nemesis::ModuleLoader _match() ' );

ok( &Nemesis::ModuleLoader::_match( \@test, 2 ) == 1,
    'Nemesis::ModuleLoader _match() ' );

