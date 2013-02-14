package Nemesis::Inject;

use Keyword::Simple;

sub import {

    # create keyword 'provided', expand it to 'if' at parse time
    Keyword::Simple::define 'nemesis_module', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
         our $Init;
         sub new(){
			my $package = shift;
			bless( {}, $package );
			%{ $package } = @_;
			$Init=$package->{\'Init\'};
			return $package;
         }
         sub export_public_methods() {   
		    my $self = shift;
		
		    return @PUBLIC_FUNCTIONS;
		}
		sub info(){
		$Init->getIO()->print_tabbed("__PACKAGE__ $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2);
		}
         ';    # inject 'if' at beginning of parse buffer
    };

    Keyword::Simple::define 'nemesis_moose_module', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
		has \'Init\' => (
			is=>\'rw\',
			required=> 1
			);
		sub export_public_methods() {   
		    return @PUBLIC_FUNCTIONS;
			}
		sub info(){
			my $self=shift;
			$self->Init->getIO()->print_tabbed(__PACKAGE__ ." $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2);
		}
         ';    # inject 'if' at beginning of parse buffer
    };

    Keyword::Simple::define 'nemesis_moosex_module', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
		has Init => (
			is=> read_write,
			required=> true
			);
		method export_public_methods() {   
		    return @PUBLIC_FUNCTIONS;
			}
		method info(){
			$self->Init->getIO()->print_tabbed(__PACKAGE__ ." $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2);
		}
         ';    # inject 'if' at beginning of parse buffer
    };

    Keyword::Simple::define 'nemesis_moosex_resource', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
		has Init => (
			is=> read_write,
			required=> true
			);

         ';    # inject 'if' at beginning of parse buffer
    };

    Keyword::Simple::define 'nemesis_moose_resource', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
		has \'Init\' => (
			is=> read_write,
			required=> true
			);

         ';    # inject 'if' at beginning of parse buffer
    };
    Keyword::Simple::define 'nemesis_resource', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = '
  our $Init;
         sub new(){
			my $package = shift;
			bless( {}, $package );
			%{ $package } = @_;
			$Init=$package->{\'Init\'};
			return $package;
         }
       
         ';    # inject 'if' at beginning of parse buffer
    };


}

sub unimport {

    # lexically disable keyword again
    Keyword::Simple::undefine 'nemesis';
}

1;
