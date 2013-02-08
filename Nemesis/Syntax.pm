package Nemesis::Syntax;

use 5.008001;

use strict;
use warnings;

use Devel::Declare::Context::Simple ();
our $VERSION = '0.01';
{
    sub nemesis(&) { $_[0]->() }

    sub import {
        my $class   = shift;
        my $keyword = 'nemesis';
        my $caller  = Devel::Declare::get_curstash_name;
        Devel::Declare->setup_for(
            $caller,
            {   $keyword => {
                    const => sub {
                        $class->parser(
                            Devel::Declare::Context::Simple->new->init(@_) );
                        }
                }
            }
        );
        no strict 'refs';
        *{"$caller\::$keyword"} = \&nemesis;
    }

    sub parser {
        my ( $class, $context ) = @_;
        $context->skip_declarator;
        $context->skipspace;
        my $proto = $context->strip_proto;
        $context->skipspace;
        my $inject;
        $inject = 'our $Init;
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
		$Init->getIO()->print_tabbed("$MODULE v$VERSION ~ $AUTHOR ~ $INFO",2);
		}';

#    if ($proto =~ /^\s*(\S+)\s+(.+?)\s*$/) {
#        $inject = "use Scope::With::Inject qw($1); set_invocant($2); no Scope::With::Inject;";
#    } else {
#        $inject = "use Scope::With::Inject; set_invocant($proto); no Scope::With::Inject;";
#    }
# prefix our injected code with code that appends a semicolon to the end of the block
        $inject = $context->scope_injector_call(';') . $inject;
        $context->inject_if_block($inject);
    }
}
1;
__END__
