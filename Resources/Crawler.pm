use MooseX::Declare;

use Nemesis::Inject;
class Resources::Crawler{
	has 'Proxy'     => 		(is=>"rw");
	has 'Result'    =>		(is=>"rw",isa=>"ArrayRef",default => sub { [] });
	has 'FieldName' =>	    (is=>"rw", default=>"q");
	has 'SearchURL' =>		(is=>"rw", default=>"http://www.google.com");
	has 'PageRegex' =>		(is=>"rw", default=>'start');
	has 'Pages'     =>		(is=>"rw", isa=>"ArrayRef",default => sub { [] });
	nemesis_moosex_resource;
	use WWW::Mechanize;
	use Regexp::Common qw /URI/;

	method search($String){
	
		my $mech = WWW::Mechanize->new();
		$mech->agent_alias( 'Windows IE 6' );
		$mech->get( $self->SearchURL );

		$mech->submit_form(
		    fields      => {
		        $self->FieldName  => $String
		    }
		);
		$self->getLinkFromPage($mech);
	}

	method getLinkFromPage($mech){
		my @URLS=$self->urlclean($mech->links);

		my @ActualURLS=@{$self->Result};
		$self->Init->getIO()->print_info("Good for now.");

		push(@{$self->Result},@URLS);
		$self->Init->getIO()->print_info("There will be ".scalar(@URLS)." URLS");


		$self->sugar;

	}

	method urlclean(@Urls){

		my @Correct;
		my $r=$self->PageRegex;
		foreach my $url(@Urls){

			if($url->url=~/($RE{URI}{HTTP})/){
				push(@Correct,$1);
			}

			if($url->url=~/$r/){
				$url->base($self->SearchURL);
				push(@{$self->Pages},$url->url_abs);
			}


		
		}
		@{$self->Pages}=$self->Init->getIO()->unici(@{$self->Pages});
		return @Correct;
	}

	method sugar(){


		$self->Init->getIO()->print_info("Found a total of ".scalar(@{$self->Result})." links");
		$self->Init->getIO()->print_tabbed(join("\t",@{$self->Result}),2);
		$self->Init->getIO()->print_info("We get also ".scalar(@{$self->Pages})." pages to crawl more");
				$self->Init->getIO()->print_tabbed(join("\t",@{$self->Pages}),2);

	}

	method fetchNext(){
		my $mech = WWW::Mechanize->new();
		$mech->agent_alias( 'Windows IE 6' );
		my $Page=shift @{$self->Pages};
		$mech->get( $Page );
		$self->getLinkFromPage($mech);

	}

}