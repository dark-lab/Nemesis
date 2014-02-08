package MiddleWare::metasploit;
use Resources::Models::Exploit;
use Resources::Models::Node;
use Nemesis::BaseModule -base;

my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Metasploit Module";
my $INFO    = "<www.dark-lab.net>";

#Funzioni che fornisco.
our @PUBLIC_FUNCTIONS
    = qw(start console clear sessionlist call test generate matchExpl);    #NECESSARY

#Attributo Processo del demone MSFRPC
has 'Process';

#Risorsa MSFRPC che mi fornirà il modo di connettermi a MSFRPC
has 'MSFRPC';
has 'DB';

sub prepare {
    my $self = shift;
    $self->MSFRPC( $self->Init->getModuleLoader->loadmodule("MSFRPC") );
    $self->DB( $self->Init->ml->getInstance("Database") );
}

sub start() {
    my $self = shift;

    #return 1 if ( $self->Process && $self->Process->is_running );

    my $Io = $self->Init->getIO();

    my $processString
        = 'msfrpcd -U '
        . $self->MSFRPC->Username . ' -P '
        . $self->MSFRPC->Password . ' -p '
        . $self->MSFRPC->Port
        . ' -S -f'; #FOREGROUND
    $Io->print_info("Starting msfrpcd service.")
        ;    #AVVIO il demone msfrpc con le configurazioni della risorsa
    my $Process
        = $self->Init->ml->loadmodule('Process');   ##Carico il modulo process
    $Process->set(
        tag  => 'msfrpcd',
        type => 'daemon',                           # tipologia demone
        code => $processString                      # linea di comando...
    );
    if ( $Process->start() ) {                      #Avvio
        $self->Process($Process)
            ;    #Nell'attributo processo del plugin ci inserisco il processo
            
        if ( $Process->is_running ) {
            $Io->print_info("Service msfrcpd started")
                ;    #Controllo se si è avviato
           # $Io->process_status($Process);    #Stampo lo status
            $Io->print_alert(
                "Now you have to give some time to metasploit to be up and running.."
            );
        }
    }

}

sub safe_database() {
    my $self = shift;
    my $result
        = $self->DB->search( { class => "Resources::Models::Exploit" } );
    while ( my $block = $result->next ) {
        foreach my $item (@$block) {
            my $result2 = $self->DB->search( { module => $item->module } );
            while ( my $block2 = $result2->next ) {
                foreach my $item2 (@$block2) {
                    if ( $item ne $item2 ) {
                        $self->DB->delete($item2);
                        $self->Init->getIO->debug("Deleting $item2");
                    }
                }
            }
        }
    }

}

sub LaunchExploitOnNode() {
    my $self    = shift;
    my $Node    = shift;
    my $Exploit = shift;
    my @OPTIONS = ( "exploits", $Exploit->module );

    #Posso usare le promises, oppure
    #master polling ogni 10 minuti.

    $self->Init->io->debug_dumper($self->MSFRPC->console_read());

    $self->MSFRPC->console_write("use ".$Exploit->module);
    $self->MSFRPC->console_write("set RHOST ".$Node->ip);
    $self->MSFRPC->console_write("set RPORT 80");
    $self->MSFRPC->console_write("run");
    $self->MSFRPC->console_write("jobs");
    sleep 3;

    $self->Init->io->debug_dumper($self->MSFRPC->console_read);

   #  my $LaunchResult = $self->MSFRPC->execute(
   #      $Exploit->type,
   #      $Exploit->module,
   #      {
   #          ##   PAYLOAD=>undef,
   #          ##   TARGET=>undef,
   #          ##   ACTION=> undef,

   #          RHOST => $Node->ip,
   #          RPORT => $Exploit->default_rport

   #      }
   #  );

   #  $self->Init->io->debug_dumper({   $Exploit->type => 0,
   #      $Exploit->module =>
   #      {
   #          ##   PAYLOAD=>undef,
   #          ##   TARGET=>undef,
   #          ##   ACTION=> undef,

   #          RHOST => $Node->ip,
   #          RPORT => 80

   #      }});

   #  my $Options = $self->MSFRPC->options( "exploits", $Exploit->module );
   #  my $Payloads = $self->MSFRPC->payloads( $Exploit->module );
   # $self->Init->getIO->debug_dumper( \$Options );
   # # $self->Init->getIO->debug_dumper( \$Payloads );
   #    $self->Init->getIO->debug_dumper( \$LaunchResult );


}

sub console(){
    my $self=shift;
    $self->MSFRPC->console_write(@_);
    $self->Init->io->debug_dumper($self->MSFRPC->console_read);


}

sub event_Resources__Exploit {
    my $self = shift;
    $self->Init->io->debug("Exploit generated correctly!");
}

sub generate() {
    my $self = shift;

    while ($self->Process->is_running ) {
        sleep 5;
        $self->Init->io->info("waiting for meta");

        if ( $self->is_up ) {
            $self->populateDB;
            last;
        }
        else {
            $self->Init->io->error("meta doesn't answer yet");

        }
    }

    #   $self->safe_database;

}

sub is_up() {
    my $self = shift;
    if ( $self->MSFRPC ) {
        my $MSFRPC   = $self->MSFRPC;
        my $response = $MSFRPC->call('module.exploits');
        if ( exists( $response->{'modules'} ) ) {
            return 1;
        }
    }

    return 0;

}

sub populateDB() {
    my $self   = shift;
    my $MSFRPC = $self->MSFRPC;
    my $DB     = $self->Init->ml->getInstance("Database");
    my $IO     = $self->Init->io;

    #  $self->start if ( !$self->Process or !$self->Process->is_running );

    if ( !$self->is_up ) {
        $IO->print_alert("Cannot sync with meta");
    }
    my $response = $MSFRPC->call('module.exploits');

    my @EXPL_LIST = @{ $response->{'modules'} };

    $IO->print_alert("Syncing db with msf exploits, this can take a while");
    $IO->print_info(
        "There are " . scalar(@EXPL_LIST) . " exploits in metasploit" );
    my $result = $DB->search( { class => "Resources::Models::Exploit" } );
    my $Counter = 0;
    while ( my $block = $result->next ) {
        foreach my $item (@$block) {
            $Counter++;
        }
    }
    $IO->print_info("$Counter of them already are in the database ");

    $Counter = 0;
    foreach my $exploit (@EXPL_LIST) {

        my $result = $DB->search( { module => $exploit } );
        my $AlreadyThere = 0;
        while ( my $block = $result->next ) {
            foreach my $item (@$block) {
                $AlreadyThere = 1;
                last;
            }
        }
        if ( $AlreadyThere == 0 ) {
            $IO->debug("Adding $exploit to Exploit DB");
            my $Information = $MSFRPC->info( "exploits", $exploit );
            my $Options = $MSFRPC->options( "exploits", $exploit );
            $MSFRPC->parse_result;

            my @Targets = values %{ $Information->{'targets'} };
            my @References = map { $_ = join( "|", @{$_} ); }
                @{ $Information->{'references'} };
            $IO->debug( join( " ", @Targets ) . " targets" );
            my $Expla = Resources::Models::Exploit->new(
                type          => "exploits",
                module        => $exploit,
                rank          => $Information->{'rank'},
                description   => $Information->{'description'},
                name          => $Information->{'name'},
                targets       => \@Targets,
                references    => \@References,
                default_rport => $Options->{'RPORT'}->{'default'}
            );
            $DB->add($Expla);
            $Counter++;
        }
        else {
            $IO->debug("Exploit already in the database");
        }
    }

    $IO->print_info(" $Counter added");
}

sub test() {
    my $self = shift;

    $self->LaunchExploitOnNode(
        Resources::Models::Node->new( ip => "127.0.0.1" ),
        Resources::Models::Exploit->new(
            type   => "exploits",
            module => "windows/misc/ib_isc_attach_database"
        )
    );

}

sub matchExpl() {
    my $self   = shift;
    my $String = shift;

    my @Objs = $self->DB->rsearch(
        {

            class  => "Resources::Models::Exploit",
            module => $String
        }
    );

    $self->Init->getIO->print_tabbed(
        "Found a total of " . scalar(@Objs) . " objects for /$String/i", 3 );
    foreach my $item (@Objs) {
        $self->Init->getIO->print_tabbed(
            "Found " . $item->module . " " . $item->name, 4 );
    }
    return @Objs;

}

sub matchNode() {

    my $self = shift;
    my $Node = shift;
    $self->Init->getIO->print_info(
        "Matching the node against Metasploit database");
    foreach my $port ( @{ $Node->ports } ) {
        my ( $porta, $service ) = split( /\|/, $port );
        foreach my $expl (
            ( $self->matchExpl($service), $self->matchPort($porta) ) )
        {
            $self->Init->getIO->print_info(
                "Exploit targets: " . join( " ", @{ $expl->targets } ) );
            foreach my $target ( @{ $expl->targets } ) {
                my $os = $Node->os;
                if ( $Node->os =~ /embedded/ ) {
                    $os = "linux";
                }    #it's a good assumption, i know
                if ( $target =~ /$os/i or $target =~ /Automatic/ ) {
                    $self->Init->getIO->print_info("$target match");
                    $Node->attachments->insert($expl);
                    last;
                }
            }
        }
    }
    return $Node;
}

sub matchPort() {
    my $self   = shift;
    my $String = shift;
    my $Objs   = $self->DB->search( { default_rport => $String } );
    $self->Init->getIO->print_tabbed(
        "Searching a matching exploit for port $String", 3 );

    my @Return;
    while ( my $chunk = $Objs->next ) {
        for my $item (@$chunk) {
            $self->Init->getIO->print_tabbed(
                "Found " . $item->module . " " . $item->name, 4 );
            push( @Return, $item );
        }
    }

    return @Return;

}

sub sessionlist() {
    my $self    = shift;
    my @OPTIONS = (
        "auxiliary",
        "server/browser_autopwn",
        {   LHOST   => "0.0.0.0",
            SRVPORT => "8080",
            URIPATH => "/"
        }
    );

    #my $response = $self->call( "session.list", @OPTIONS );
    $self->MSFRPC->call("session.list");

}

sub call() {
    my $self   = shift;
    my $String = shift;
    $self->MSFRPC->call($String);
}

sub clear() {
    my $self = shift;
    $self->Process->destroy() if ( $self->Process );

#Il metodo clear viene chiamato quando chiudiamo tutto, dunque se ho un processo attivo, lo chiudo!
}

sub event_tcp() {

    # my $IO=$Init->io;
    # my $PrivIp;
    # my $PubIp;
    # my $SourcePort;
    # my $DestPort;
    # foreach my $Packet(@Packet_info){
    #      if( $Packet->isa("NetPacket::IP") ) {
    #             my $InfoIP=Net::IP->new($Packet->{src_ip});
    #             my $SrcType=$InfoIP->iptype;
    #              $InfoIP=Net::IP->new($Packet->{dest_ip});
    #             my  $DstType=$InfoIP->iptype;
    #             if($SrcType eq "PRIVATE"  ) {
    #                 $PrivIp=$SrcType;
    #             }else {
    #                 $PubIp=$SrcType;
    #             }
    #             if($DstType eq "PRIVATE"){
    #                 $PrivIp=$DstType;
    #             } else {
    #                 $PubIp=$DstType;
    #             }
    #         } elsif( $Packet->isa("NetPacket::TCP") ) {
    #             $SourcePort=$Packet->{src_port};
    #             $DestPort=$Packet->{dest_port};
    #         }
    # }

# if(defined($PrivIp)){
#                        my $DBHost;
#    $Init->io->info("searching for matches for $PrivIp : $SourcePort/$DestPort");

    #    my $results=$self->DB->search(ip => $PrivIp);

    #    while( my $chunk = $results->next ){
    #                  foreach my $foundhost (@$chunk){
    #                   $DBHost=$foundhost;
    #                   last;
    #               }
    #     }

#   foreach my $FoundExploit(($self->matchPort($SourcePort),$self->matchPort($DestPort))){
#   #Update Database with new information
#     #Launch Exploit

    #    }
    # }
}

1;

