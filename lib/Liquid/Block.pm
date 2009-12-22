package Liquid::Block;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../lib';
    use Liquid::Error;
    our @ISA = qw[Liquid::Document];

    sub new {
        my ($class, $args) = @_;
        raise Liquid::ContextError {message => 'Missing parent argument',
                                    fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Liquid::SyntaxError {
             message => 'else tags are non-conditional: ' . $args->{'markup'},
             fatal   => 1
            }
            if $args->{'tag_name'} eq 'else' && $args->{'args'};
        return
            bless {tag_name  => $args->{'tag_name'},
                   condition => ($args->{'tag_name'} eq 'else'
                                 ? 1
                                 : Liquid::Condition->new(
                                               {attrs  => $args->{'attrs'},
                                                parent => $args->{'parent'}
                                               }
                                 )
                   ),
                   nodelist => [],
                   parent   => $args->{'parent'}
            }, $class;
    }
}
1;
