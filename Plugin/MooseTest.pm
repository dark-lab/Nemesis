package Plugin::MooseTest;

#use Nemesis::Inject;
use Nemesis::BaseModule -base;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Moose testing plugin";
our $INFO    = "<www.dark-lab.net>";

our @PUBLIC_FUNCTIONS = qw(test);

#Declare::Devel::Lexer it's a little buggy, so you may encounter some problems inside the
#nemesis block here are few ints:
#       *  No comments inside nemesis block{}
#       *  Somethimes (i didn't have time to track that bug) you need to close your block in one line (so your graph must be at the endofline )

# nemesis module {

#     init()->io->info("my test :)");

# }

has 'Process' => ( );

sub test() {
    my $self = shift;

#$self->Init->getIO()->print_info($self->Init->getModuleLoader->_findLibName("http://dark-lab.net/Speech.pm"));
#$self->Init->getModuleLoader->loadmodule("http://dark-lab.net/Process.pm");
#  my $Process=$self->Init->getModuleLoader->loadmodule("Process");
# $Process->set(
#     type=> "thread",
#     module=>"Run"
#     );
# $Process->start();
# $self->Process($Process);
# my $MSFRPC=$self->Init->getModuleLoader->loadmodule("MSFRPC");
# $MSFRPC->Username("Cane");
    my $DB = $self->Init->getModuleLoader->loadmodule("DB");
    $DB->connect();

    #$DB->add($MSFRPC);
    my $Data_Bulk = $DB->list_obj();
    Lista tutti gli oggetti $self->Init->getIO->print_info(
        "test 1:  ricerca classe di tipo Resources::Node");

    #   my $results=$DB->search(class => "Resources::Node");

#       while( my $block = $results->next ) {
#           foreach my $item ( @{$block} ) {
#               $self->Init->getIO->debug($item->ip.": ".join(",",@{$item->ports}),__PACKAGE__);
#               $self->Init->getIO->debug("Possible vulns ".$item->attachments->size);

    #           }
    #       }

}

sub clear() {
    my $self = shift;
    $self->Process()->destroy() if ( $self->Process );
}

#  __PACKAGE__->meta->make_immutable;
1;

