package Resources::Speech;
use MooseX::DeclareX
    keywords => [qw(class)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];

class Resources::Speech{

	has 'Language' => (isa=>'Str', is=>'rw', default=>'spike');
	has 'Password' => (isa=>'Str', is=>'rw', default=>'spiketest');
	has 'Host' => (isa=>'Str', is=>'rw', default=>'127.0.0.1');
	has 'Port' => (isa=>'Int', is=>'rw', default=>5553);
	has 'API' => (isa=>'Str', is=>'rw', default=>'/api/');


method convert($file) {
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
    print "[*] Sintesi vocale di " . $file . "\n";

    if ( $file !~ /\.flac/ ) {
        $converted = 1;
        print "[*] Conversione a flac in corso...\n";
        system( "flac -f '" . $file . "' >/dev/null 2>&1" );
    }
    print "[*] Abbasso la frequenza...\n";
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