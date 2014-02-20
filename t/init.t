use Test::Simple tests => 4;
use Nemesis;

my $Init = new Nemesis::Init();

ok( defined($Init) && $Init->isa("Nemesis::Init"),
    'Nemesis::Init initialization ' );

ok( ref( $Init->ml ) eq ref( $Init->getModuleLoader )
        and ref( $Init->ml ) eq ref( $Init->moduleloader ),
    'Nemesis::Init ModuleLoader aliases'
);

ok( ref( $Init->getInterfaces ) eq ref( $Init->interfaces ),
    'Nemesis::Init aliases for interfaces'
);
ok( ref( $Init->getSession ) eq ref( $Init->session ),
    'Nemesis::Init aliases for session'
);

