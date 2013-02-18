package Resources::Speech;
use MooseX::Declare;
use Nemesis::Inject;
class Resources::Speech{

	has 'Language' => (isa=>'Str', is=>'rw', default=>'it');

    nemesis_moosex_resource;

    method flac2speech($file) {
        #Absolute path of file
        my $flac_file = $file;
        my $converted = 0;
        my $url =
    "https://www.google.com/speech-api/v1/recognize?xjerr=1&client=speech2text&lang="
          . $self->Language
          . "&maxresults=10";
        $flac_file =~ s/\..*//g;
        $flac_file .= ".flac";
        my @hypotheses = ();
        my $audio;
        if ( $file !~ /\.flac/ ) {
            $converted = 1;
            $self->Init->getIO()->exec( "flac -f '" . $file . "' >/dev/null 2>&1" );
        }
        $self->Init->getIO()->exec( "ffmpeg -i "
              . $flac_file
              . " -ar 16000 -y "
              . $flac_file
              . " >/dev/null 2>&1" );

        open( FILE, "<" . $flac_file );
        while (<FILE>) {
            $audio .= $_;
        }
        close(FILE);
        unlink($flac_file);
        my $ua       = LWP::UserAgent->new;
        my $response = $ua->post(
            $url,
            Content_Type => "audio/x-flac; rate=16000",
            Content      => $audio
        );
        my $result;
        if ( $response->is_success ) {
            $result = $response->content;
        }
        while ( $result =~ m/\"utterance\"\:\"(.*?)\"/g ) {
            push( @hypotheses, $1 );
        }
        return @hypotheses;
    }


}