package Nemesis::Inject;

use Keyword::Simple;

sub import {

    # create keyword 'provided', expand it to 'if' at parse time
    Keyword::Simple::define 'nemesis_module', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = 'our $Init; if(!eval{__PACKAGE__->can("meta")}) {  my $code=\'sub new(){my $package = shift;bless( {}, $package );%{ $package } = @_;$Init=$package->{\\\'Init\\\'};return $package;}sub export_public_methods() {   my $self = shift; return @PUBLIC_FUNCTIONS,"info";}sub info(){$Init->getIO()->print_tabbed("__PACKAGE__ $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2);}\'; eval $code;   } else { __PACKAGE__->meta->add_attribute( \'Init\' => ( is => \'rw\',required=> 1    ) );__PACKAGE__->meta->add_method( \'BUILD\' => sub { my $self=shift;my $args=shift; $Init=$args->{Init}; } );__PACKAGE__->meta->add_method( \'info\' => sub { my $self=shift;            $self->Init->getIO()->print_tabbed(__PACKAGE__ ." $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2); } );__PACKAGE__->meta->add_method( \'export_public_methods\' => sub { return @PUBLIC_FUNCTIONS,"info"; } ); } ';    # inject 'if' at beginning of parse buffer
    };



    Keyword::Simple::define 'nemesis_resource', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = 'our $Init; if(!eval{__PACKAGE__->can("meta")}) {  my $code=\'sub new(){my $package = shift;bless( {}, $package );%{ $package } = @_;$Init=$package->{\\\'Init\\\'};return $package;}\'; eval $code;   } else {__PACKAGE__->meta->add_method( \'BUILD\' => sub { my $self=shift;my $args=shift; $Init=$args->{Init}; } ); __PACKAGE__->meta->add_attribute( \'Init\' => ( is => \'rw\',required=> 1    ) );} ';    # inject 'if' at beginning of parse buffer
    };
    Keyword::Simple::define 'nemesis_resource_mojo', sub {
        my ($ref) = @_;
        substr( $$ref, 0, 0 ) = 'our $Init; my $code=\' sub setInit(){  my $self=shift;  $Init=$_[0];}\'; eval $code; ';    # inject 'if' at beginning of parse buffer
    };
       
}

sub unimport {

    # lexically disable keyword again
    Keyword::Simple::undefine 'nemesis_module';
    Keyword::Simple::undefine 'nemesis_resource';
    Keyword::Simple::undefine 'nemesis_resource_mojo';

}

1;
