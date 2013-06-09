package Plugin::InfoGathering;

use MooseX::Declare;

use Nemesis::Inject;
class Plugin::InfoGathering {

#my $pcap_file =
#   $Init->session->new_file( $dev . "-ettercap-" . $env->time() . ".pcap" ,__PACKAGE__);

    my $Process = $Init->getModuleLoader()->loadmodule("Process");
    $Process->set(
        type => 'system',
        code => "Wsorrow -> -> ->"
    );

    $Process->output;          #Return Handle
    $Process->get_output;      #Return String of output
    $Process->get_output_file; #Return the filename where the output is saved.
    $Proces->is_running;       #It's running or not?

}
