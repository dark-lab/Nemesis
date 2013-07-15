package Nemesis::Inject;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ nemesis got/;
use Devel::Declare::Lexer::Factory qw( :all );
use Data::Dumper;
sub import {
    my $caller = caller;
    Devel::Declare::Lexer::import_for( $caller, "nemesis" );
    Devel::Declare::Lexer::import_for( $caller, "got" );

}
BEGIN {

    Devel::Declare::Lexer::lexed(
        got =>
            sub
        {    ## this is taken form Declare::Lexer examples, thank you mate!
            my ($stream_r) = @_;

            my @stream = @{$stream_r};
            my @start  = @stream[ 0 .. 1 ];
            my @end    = @stream[ 2 .. $#stream ];

            shift @stream;    # remove keyword
            while (
                ref( $stream[0] )
                =~ /Devel::Declare::Lexer::Token::Whitespace/ )
            {
                shift @stream;
            }

            # Get the name (could be string or variable)
            my $name = shift @stream;
            if ( ref( $name =~ /Devel::Declare::Lexer::Token::Variable/ ) ) {
                $name = shift @stream;
            }

            # Consume whitespace and =>
            while ( $stream[0]->{value} !~ /\(/ ) {
                shift @stream;
            }

            my $nest      = 0;
            my @propblock = ();
            shift @stream;    # consume the (
            while (@stream) {
                if (ref( $stream[0] )
                    =~ /Devel::Declare::Lexer::Token::LeftBracket/ )
                {
                    $nest++;
                }
                elsif (
                    ref( $stream[0] )
                    =~ /Devel::Declare::Lexer::Token::RightBracket/ )
                {
                    last if $nest == 0 && $stream[0]->{value} =~ /\)/;
                    $nest--;
                }
                push @propblock, shift @stream;    # consume tokens
            }
            shift @stream;                         # consume the )

            my @output = _stream(
                $stream_r,
                [   _statement( [ _bareword(1) ] ),
                    _statement(
                        [   _bareword('my'),
                            _whitespace(' '),
                            _var_assign(
                                [   _variable(
                                        '$', '__props_lexer_' . $name->{value}
                                    )
                                ],
                                [ _block( [ @propblock ], '{' ) ]
                            )
                        ]
                    ),
                    _statement(
                        [   _var_assign(
                                [   _variable(
                                        '$',
                                        '__props_lexer_'
                                            . $name->{value}
                                            . '->{\'value\'}'
                                    )
                                ],
                                [   _variable(
                                        '$',
                                        '__props_lexer_'
                                            . $name->{value}
                                            . '->{\'default\'}'
                                    )
                                ]
                            )
                        ]
                    ),
                    _sub(
                        $name->{value},
                        [   _block(
                                [   _statement(
                                        [   _bareword('my'),
                                            _whitespace(' '),
                                            _var_assign(
                                                [   _block(
                                                        [   _variable(
                                                                '$', 'value'
                                                            )
                                                        ],
                                                        '('
                                                    )
                                                ],
                                                [ _variable( '@', '_' ) ]
                                            )
                                        ]
                                    ),
                                    _if([ _variable( '$', 'value' ), ],
                                        [   _var_assign(
                                                [   _variable(
                                                        '$',
                                                        '__props_lexer_'
                                                            . $name->{value}
                                                            . '->{\'value\'}'
                                                    )
                                                ],
                                                [ _variable( '$', 'value' ) ]
                                            )
                                        ]
                                    ),
                                    _return(
                                        [   _variable(
                                                '$',
                                                '__props_lexer_'
                                                    . $name->{value}
                                                    . '->{\'value\'}'
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    ),
                ]
            );

            # Stick everything else back on the end
            push @output, @stream;
            return \@output;
        }
    );

    Devel::Declare::Lexer::lexed(
        nemesis => sub {
            my ($stream_r) = @_;

            my @stream = @{$stream_r};
            my @start  = @stream[ 0 .. 1 ];
            my @end    = @stream[ 2 .. $#stream ];
            my @output;
            my $name = shift @end;    # get module type

            # Capture the variables
            my @vars = ();

            # Consume everything until the start of block
            while ( $end[0]->{value} !~ /\{/ ) {
                my $tok = shift @end;
                next
                    if ref($tok)
                    =~ /Devel::Declare::Lexer::Token::(Left|Right)Bracket/;
                next if ref($tok) =~ /Devel::Declare::Lexer::Token::Operator/;
                next
                    if ref($tok)
                    =~ /Devel::Declare::Lexer::Token::Whitespace/;

                # If we've got a variable, capture it
                if ( ref($tok) =~ /Devel::Declare::Lexer::Token::Variable/ ) {
                    push @vars, [ $tok, shift @end ];
                }
            }

            shift @end;    # remove the {

            #unshift(@end,_whitespace(" "),_statement([_bareword('1')]));
            if ( $name->{value} eq "module" ) {
                @output = _stream(
                    \@start,
                    [   _statement( [ _bareword(1) ] ),    #1;
                        _statement(
                            [   _bareword('our'), _whitespace(' '),
                                _variable( '$', 'Init' )
                            ]
                        ),                                 # our $Init;
                        _if([
                                # if(
                                _bareword('!eval'),
                                _block(
                                    [   _bareword("__PACKAGE__->can"),
                                        _block(
                                            [ _string( '"', 'meta' ) ], "("
                                        )
                                    ],
                                    "{"
                                    )

                                    # !eval{__PACKAGE->can("meta")}
                            ],
                            [    #THEN
                                _statement(
                                    [   _bareword('my'),
                                        _whitespace(' '),
                                        _variable( '$', 'code' ),
                                        _operator('='),
                                        _block(
                                            [   _sub(
                                                    "new",
                                                    [   _block(
                                                            [   _statement(
                                                                    [   _bareword(
                                                                            'my'
                                                                        ),
                                                                        _whitespace(
                                                                            ' '
                                                                        ),
                                                                        _variable(
                                                                            '$',
                                                                            'package'
                                                                        ),
                                                                        _operator(
                                                                            '='
                                                                        ),
                                                                        _bareword(
                                                                            'shift'
                                                                        )
                                                                    ]
                                                                ),
                                                                _statement(
                                                                    [   _bareword(
                                                                            'bless'
                                                                        ),
                                                                        _block(
                                                                            [   _bareword(
                                                                                    "{},"
                                                                                    )
                                                                                ,
                                                                                _variable(
                                                                                    '$',
                                                                                    "package"
                                                                                )
                                                                            ],
                                                                            "("
                                                                        )
                                                                    ]
                                                                ),
                                                                _statement(
                                                                    [   _var_assign(
                                                                            [   _variable(
                                                                                    '%',
                                                                                    '{$package}'
                                                                                )
                                                                            ],
                                                                            [   _variable(
                                                                                    '@',
                                                                                    '_'
                                                                                )
                                                                            ]
                                                                        )
                                                                    ]
                                                                ),
                                                                _statement(
                                                                    [   _var_assign(
                                                                            [   _variable(
                                                                                    '$',
                                                                                    'Init'
                                                                                )
                                                                            ],
                                                                            [   _variable(
                                                                                    '$',
                                                                                    'package->{\\\'Init\\\'}'
                                                                                )
                                                                            ]
                                                                        )
                                                                    ]
                                                                ),
                                                                _return(
                                                                    [   _variable(
                                                                            '$',
                                                                            'package'
                                                                        )
                                                                    ]
                                                                    )

                                                            ],
                                                            "{"
                                                            )

                                                    ]
                                                ),
                                                _sub(
                                                    "export_public_methods",
                                                    [   _block(
                                                            [   _return(
                                                                    [   _block(
                                                                            [   _variable(
                                                                                    '@',
                                                                                    'PUBLIC_FUNCTIONS'
                                                                                    )
                                                                                ,
                                                                                _bareword(
                                                                                    ','
                                                                                    )
                                                                                ,
                                                                                _string(
                                                                                    '"',
                                                                                    'info'
                                                                                )
                                                                            ],
                                                                            "("
                                                                            )

                                                                    ]

                                                #   '@PUBLIC_FUNCTIONS,"info"'
                                                                ),
                                                            ],
                                                            "{"
                                                            )

                                                    ]
                                                ),

                                                _sub(
                                                    "info",
                                                    [   _block(
                                                            [   _statement(
                                                                    [   _bareword(
                                                                            '$Init->getIO()->print_tabbed("__PACKAGE__ $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2)'
                                                                        )
                                                                    ]
                                                                )
                                                            ],
                                                            "{"
                                                            )

                                                    ]
                                                ),
                                                _sub(
                                                    "Init",
                                                    [   _block(
                                                            [   _return(
                                                                    [   _variable(
                                                                            '$',
                                                                            'Init'
                                                                        )
                                                                    ]
                                                                )
                                                            ],
                                                            "{"
                                                            )

                                                    ]
                                                ),
                                                _sub(
                                                    "init",
                                                    [   _block(
                                                            [   _return(
                                                                    [   _variable(
                                                                            '$',
                                                                            'Init'
                                                                        )
                                                                    ]
                                                                )
                                                            ],
                                                            "{"
                                                            )

                                                    ]
                                                ),
                                            ],
                                            "'"
                                        ),    #my $code ='
                                    ]
                                ),
                                _statement(
                                    [   _bareword("eval"),
                                        _block(
                                            [ _variable( '$', 'code' ) ], "("
                                        )
                                    ]
                                )
                            ],
                            undef,            #elsif
                            [   _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->make_mutable()'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_attribute( \'Init\' => ( is => \'rw\',required=> 1    ) )'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'BUILD\' => sub { my $self=shift;my $args=shift; $Init=$args->{Init}; } )'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'info\' => sub { my $self=shift;$self->Init->getIO()->print_tabbed(__PACKAGE__ ." $MODULE v$VERSION ~ $AUTHOR ~ $INFO",2); } )'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'init\' => sub { return $Init; } )'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'export_public_methods\' => sub { return @PUBLIC_FUNCTIONS,"info"; } )'
                                        )
                                    ]
                                )
                            ]    #else

                        ),
                        _sub(
                            "prepare",
                            [   _block(

                                    [ 

                                            _statement([_bareword('1')]),

                                      _statement(
                                            [   _bareword('my'),
                                                _variable( '$', 'self' )
                                            ]
                                        ),
                                        _statement(
                                            [

                                                _var_assign(
                                                    [   _variable(
                                                            '$', 'self'
                                                        )
                                                    ],
                                                    [ _bareword('shift') ]
                                                    )

                                            ]
                                        ),
                                     #    new                                            Devel::Declare::Lexer::Token::Newline,
                                      #  new                                           Devel::Declare::Lexer::Token::Newline,
                                        _stream( undef, \@end ),
                              #          new                                           Devel::Declare::Lexer::Token::Newline
                                    ],
                                    '{',
                                    { no_close => 1 }
                                    )
                                , # don't close it ( #FIXME lexer bug, stops at first ; )
                            ]
                            )

                    ]
                );

              #  print Dumper(@output);
                #     print map { $_ = $_->get if $_->can("get") } @output;
            }
            elsif ( $name->{value} eq "resource" ) {
                @output = _stream(
                    \@start,
                    [   _statement( [ _bareword(1) ] ),
                        _statement(
                            [   _bareword('our'), _whitespace(' '),
                                _variable( '$', 'Init' )
                            ]
                        ),    #ENDS WITH ;
                        _if([
                                #IF
                                _bareword('!eval'),
                                _block(
                                    [   _bareword("__PACKAGE__->can"),
                                        _block(
                                            [ _bareword('"meta"') ], "("
                                        )
                                    ],
                                    "{"
                                )
                            ],
                            [    #THEN

                                _statement(
                                    [   _bareword('my'),
                                        _whitespace(' '),
                                        _variable( '$', 'code' ),
                                        _operator('='),
                                        _bareword("'"),
                                        _sub(
                                            "new",
                                            [   _block(
                                                    [   _statement(
                                                            [   _bareword(
                                                                    'my'),
                                                                _whitespace(
                                                                    ' '),
                                                                _variable(
                                                                    '$',
                                                                    'package'
                                                                ),
                                                                _operator(
                                                                    '='),
                                                                _bareword(
                                                                    'shift'
                                                                )
                                                            ]
                                                        ),
                                                        _statement(
                                                            [   _bareword(
                                                                    'bless'
                                                                ),
                                                                _block(
                                                                    [   _bareword(
                                                                            "{},"
                                                                        ),
                                                                        _variable(
                                                                            '$',
                                                                            "package"
                                                                        )
                                                                    ],
                                                                    "("
                                                                )
                                                            ]
                                                        ),
                                                        _statement(
                                                            [   _var_assign(
                                                                    [   _variable(
                                                                            '%',
                                                                            '{$package}'
                                                                        )
                                                                    ],
                                                                    [   _variable(
                                                                            '@',
                                                                            '_'
                                                                        )
                                                                    ]
                                                                )
                                                            ]
                                                        ),
                                                        _statement(
                                                            [   _var_assign(
                                                                    [   _variable(
                                                                            '$',
                                                                            'Init'
                                                                        )
                                                                    ],
                                                                    [   _variable(
                                                                            '$',
                                                                            'package->{\\\'Init\\\'}'
                                                                        )
                                                                    ]
                                                                )
                                                            ]
                                                        ),
                                                        _return(
                                                            [   _variable(
                                                                    '$',
                                                                    'package'
                                                                )
                                                            ]
                                                            )

                                                    ],
                                                    "{"
                                                    )

                                            ]
                                        ),
                                        _sub(
                                            "init",
                                            [   _block(
                                                    [   _statement(
                                                            [   _bareword(
                                                                    'my'),
                                                                _whitespace(
                                                                    ' '),
                                                                _variable(
                                                                    '$',
                                                                    'self'
                                                                ),
                                                                _operator(
                                                                    '='),
                                                                _bareword(
                                                                    'shift')
                                                            ]
                                                        ),
                                                        _return(
                                                            [   _variable(
                                                                    '$',
                                                                    'Init'
                                                                )
                                                            ]
                                                        )
                                                    ],
                                                    "{"
                                                    )

                                            ]
                                        ),
                                        _bareword("'")
                                    ]
                                ),
                                _statement(
                                    [   _bareword("eval"),
                                        _block(
                                            [ _variable( '$', 'code' ) ],
                                            "("
                                        )
                                    ]
                                    )

                            ],
                            undef,    #elsif
                            [

                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->make_mutable()'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_attribute( \'Init\' => ( is => \'rw\',required=> 1    ) )'
                                        )
                                    ]
                                ),

                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'BUILD\' => sub { my $self=shift;my $args=shift; $Init=$args->{Init}; } )'
                                        )
                                    ]
                                ),
                                _statement(
                                    [   _bareword(
                                            '__PACKAGE__->meta->add_method( \'init\' => sub { my $self=shift;return $self->Init; } );'
                                        )
                                    ]
                                )
                            ]    #else

                        ),
                         _sub(
                            "prepare",
                            [   _block(
                                    [   


                                            _statement([_bareword('1')]),
                                            _statement(
                                            [   _bareword('my'),
                                                _whitespace(' '),
                                                _variable( '$', 'self' ),
                                                _operator('='),
                                                _bareword('shift')
                                            ]
                                        ),
                                        new
                                            Devel::Declare::Lexer::Token::Newline,
                                        new
                                            Devel::Declare::Lexer::Token::Newline,
                                        _stream( undef, \@end ),
                                        new
                                            Devel::Declare::Lexer::Token::Newline
                                    ],
                                    '{',
                                    { no_close => 1 }
                                    )
                                , # don't close it ( #FIXME lexer bug, stops at first ; )
                            ]
                            ),
                    ]
                );
            }
            elsif ( $name->{value} eq "mojo" ) {
                @output = _stream(
                    \@start,
                    [   _statement( [ _bareword(1) ] ),
                        _statement(
                            [   _bareword('our'), _whitespace(' '),
                                _variable( '$', 'Init' )
                            ]
                        ),    #ENDS WITH ;
                        _sub(
                            "init",
                            [   _block(
                                    [   _return(
                                            [ _variable( '$', 'Init' ) ]
                                        )
                                    ],
                                    "{"
                                    )

                            ]
                        ),
                        _sub(
                            "setInit",
                            [   _statement('my $self=shift'),
                                _statement('$Init=$_[0]')

                            ]
                        ),
                        _sub(
                            "prepare",
                            [   _block(
                                    [   
                                            _statement([_bareword('1')]),

                                    _statement(
                                            [   _bareword('my'),
                                                _whitespace(' '),
                                                _variable( '$', 'self' ),
                                                _operator('='),
                                                _bareword('shift')
                                            ]
                                        ),
                                        new
                                            Devel::Declare::Lexer::Token::Newline,
                                        new
                                            Devel::Declare::Lexer::Token::Newline,
                                        _stream( undef, \@end ),
                                        new
                                            Devel::Declare::Lexer::Token::Newline
                                    ],
                                    '{',
                                    { no_close => 1 }
                                    )
                                , # don't close it ( #FIXME lexer bug, stops at first ; )
                            ]
                            )

                    ]
                );
            }

            #print Dumper(@output);
            return \@output;

            }

        )

}



1;
