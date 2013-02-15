#!/usr/bin/perl
use Getopt::Long;
use Term::ReadLine;
use Nemesis;
my $Init         = new Nemesis::Init();
$SIG{'INT'} = sub { $Init->sighandler(); };
if(@ARGV==0){
	$Init->getIO()->print_error("I need something to eat");
}
foreach my $ARG(@ARGV){
	$Init->getSession()->wrap($ARG);
}