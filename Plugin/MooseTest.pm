package Plugin::MooseTest;
use Moose;
use Nemesis::Inject;
	
	our $VERSION = '0.1a';
	our $AUTHOR  = "skullbocks & mudler";
	our $MODULE  = "Moose test module";
	our $INFO    = "<www.dark-lab.net>";

	our @PUBLIC_FUNCTIONS=qw(info test);

	nemesis_moose_module;

	sub test
	{
		my $self=shift;
		$self->Init->getIO()->print_info("Ciao");
		$self->Init->getIO()->debug_dumper($self->Init);
	}


1;