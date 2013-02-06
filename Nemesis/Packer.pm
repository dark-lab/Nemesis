package Nemesis::Packer;
use App::Packer::PAR;
#use strict;
use warnings;
use PAR::Packer ();


use PAR ();
use Module::ScanDeps ();;
	use Acme::EyeDrops;
	use Carp qw(croak);

	our $Init;



	sub new(){
		my $package = shift;
		bless( {}, $package );
		%{$package} = @_;
		$Init = $package->{'Init'};
		croak 'No init' if !exists( $package->{'Init'} );
		return $package;
	}

	sub pack(){
		my $self=shift;
		my ($What,$FileName)=@_;
		my $parpath=$Init->getEnv()->wherepath("par.pl");
		chdir($parpath);
		@OPTS=($What);
		$Init->getIO()->debug("Chdir to $parpath");
		App::Packer::PAR->new( frontend=> Module::ScanDeps, 
			backend=> PAR::Packer,
			backopts => {P=>1 , o=>$FileName},
			args	=> \@OPTS
		)->go;
		$Init->getSession()->safechdir;

	}


1;