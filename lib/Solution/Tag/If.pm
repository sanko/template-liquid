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
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'} || $args->{'attrs'} !~ m[\S$];
        my $condition = $args->{'attrs'};
        my $self = bless {name     => $args->{'tag_name'} . '-' . $condition,
                          blocks   => [],
                          tag_name => $args->{'tag_name'},
                          template => $args->{'template'},
                          parent   => $args->{'parent'},
                          markup   => $args->{'markup'},
                          end_tag  => 'end' . $args->{'tag_name'},
                          conditional_tag => qr[^(?:else|else?if)$]
        }, $class;
        push @{$self->{'blocks'}},
            Solution::Block->new({tag_name => $args->{'tag_name'},
                                  attrs    => $args->{'attrs'},
                                  template => $args->{'template'},
                                  parent   => $self
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
                                  template => $args->{'template'},
                                  parent   => $self
                                 },
                                 $tokens
            );
    }

    sub render {
        my ($self) = @_;
        for my $block (@{$self->{'blocks'}}) {
            return $block->render()
                if grep { $_ || 0 } @{$block->{'conditions'}};
        }
    }
}
1;
