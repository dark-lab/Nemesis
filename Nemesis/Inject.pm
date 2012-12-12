package Nemesis::Inject;

	
 use Keyword::Simple;
 
 sub import {
     # create keyword 'provided', expand it to 'if' at parse time
     Keyword::Simple::define 'nemesis_module', sub {
         my ($ref) = @_;
         substr($$ref, 0, 0) = '
         our $Init;
         sub new(){
	my $package = shift;
	bless( {}, $package );
	%{ $package } = @_;
$Init=$package->{\'Init\'};
	return $package;
         }
         
         
         ';  # inject 'if' at beginning of parse buffer
     };
 }
 
 sub unimport {
     # lexically disable keyword again
     Keyword::Simple::undefine 'nemesis';
 }

1;