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

    method SpecchToText($file){
		my $flac_file = $file;
		my $converted = 0;
		my $url =
	"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=speech2text&lang="
		  . $lang
		  . "&maxresults=10";
		$flac_file =~ s/\..*//g;
		$flac_file .= ".flac";
		my @hypotheses = ();
		my $audio      = '';
		$self->Init->getIO()->print_info("Sintesi vocale di " . $file);

		if ( $file !~ /\.flac/ ) {
			$converted = 1;
			$self->Init->getIO()->print_info("Conversione a flac");
			system( "flac -f '" . $file . "' >/dev/null 2>&1" );
		}
		$self->Init->getIO()->print_info("Abbasso la frequenza a 16000 rate");
		system( "ffmpeg -i "
			  . $flac_file
			  . " -ar 16000 -y "
			  . $flac_file
			  . " >/dev/null 2>&1" );

		open( FILE, "<" . $flac_file );
		while (<FILE>) {
			$audio .= $_;
		}
		if ( $converted == 1 ) {
			unlink($flac_file);
		}
		unlink("speech.wav");
		close(FILE);
	        print "[*] Sintetizzo...\n";
		my $ua       = LWP::UserAgent->new;
		my $response = $ua->post(
			$url,
			Content_Type => "audio/x-flac; rate=16000",
			Content      => $audio
		);
		if ( $response->is_success ) {
			$result = $response->content;
		}
		while ( $result =~ m/\"utterance\"\:\"(.*?)\"/g ) {
			push( @hypotheses, $1 );
		}

		debug( "Non sono riuscito a sintetizzare: " . $result ) if @hypotheses <= 0;
		return @hypotheses;

    }

}

1;
