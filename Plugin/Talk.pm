package Plugin::Talk;

#use Moose;
use MooseX::DeclareX
    keywords => [qw(class)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];
use Nemesis::Inject;

class Plugin::Talk {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "This is an interface to the Packer library";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info export exportCli);

    nemesis_moosex_module;

    method export( $What, $FileName ) {
        $self->Init->getIO()->print_info("Packing $What in $FileName");
            $self->Init->getPacker()->pack( $What, $FileName );
            $self->Init->getIO()->print_info("Packed $What in $FileName");
        } method exportCli($Where) {
        my $path = $self->Init->getEnv()->getPathBin();
            $self->export( $path . "/cli.pl", $Where );
            $self->Init->getIO()
            ->print_info("Export completated, $Where created");
        }

}

1;
