package Plugin::Bundle;


use MooseX::Declare;

class Plugin::Bundle {


    use Nemesis::Inject;
    use namespace::autoclean;

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "This is an interface to the Packer library";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(export exportCli exportWrap);

    nemesis_module;

    method export( $What, $FileName ) {
        $self->Init->getIO()->print_info("Packing $What in $FileName");
            $self->Init->getPacker()->pack( $What, $FileName );
            $self->Init->getIO()->print_info("Packed $What in $FileName");
        } 

    method exportCli($Where) {
        my $path = $self->Init->getEnv()->getPathBin();
            $self->export( $path . "/cli.pl", $Where );
            $self->Init->getIO()
            ->print_info("Export completated, $Where created");
        }
    method exportWrap($Where) {
    my $path = $self->Init->getEnv()->getPathBin();
        $self->export( $path . "/wrapper.pl", $Where );
        $self->Init->getIO()
        ->print_info("Export completated, $Where created");
    }

}

1;
