package Solution::Tag::If;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('if') if $Solution::VERSION;

    sub new {
        my ($class, $args, $tokens) = @_;
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'};
        if ($args->{'attrs'} !~ m[\S$]) {
            raise Solution::SyntaxError {
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
            };
        }
        my $condition = $args->{'attrs'};
        my $self = bless {name     => $args->{'tag_name'} . '-' . $condition,
                          blocks   => [],
                          tag_name => $args->{'tag_name'},
                          parent   => $args->{'parent'},
                          markup   => $args->{'markup'},
                          end_tag  => 'end' . $args->{'tag_name'},
                          conditional_tag => qr[^(?:else|else?if)$]
        }, $class;
        push @{$self->{'blocks'}},
            Solution::Block->new({tag_name => $args->{'tag_name'},
                                  attrs    => $args->{'attrs'},
                                  parent   => $args->{'parent'}
                                 }
            );
        $self->parse($tokens);
        {    # finish final block
            ${$self->{'blocks'}[-1]}{'nodelist'} = $self->{'nodelist'};
            $self->{'nodelist'} = [];
        }
        return $self;
    }

    sub push_block {
        my ($self, $args, $tokens) = @_;
        {    # finish previous block
            ${$self->{'blocks'}[-1]}{'nodelist'} = $self->{'nodelist'};
            $self->{'nodelist'} = [];
        }
        push @{$self->{'blocks'}},
            Solution::Block->new({tag_name => $args->{'tag_name'},
                                  attrs    => $args->{'attrs'},
                                  parent   => $args->{'parent'}
                                 },
                                 $tokens
            );
    }

    sub render {
        my ($self) = @_;
        for my $block (@{$self->{'blocks'}}) {
            return $block->render()
                if grep { $_->is_true ? 1 : 0 } @{$block->{'conditions'}};
        }
    }
}
1;
