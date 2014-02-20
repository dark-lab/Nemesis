use Test::Simple tests => 4;
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

ok (reftype(\$Init->ml->export_public_methods()) eq 'ARRAY', 'Nemesis::ModuleLoader export_public_methods()');
