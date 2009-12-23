package Solution::Document;
{
    use strict;
    use warnings;
    use lib '../';
    our $VERSION = 0.001;
    use Solution::Variable;
    use Solution::Utility;
    use overload
        '""'     => 'render',
        fallback => 1;
    sub parent  { return $_[0]->{'parent'} }
    sub root    { return $_[0]->parent->root; }
    sub context { return $_[0]->parent->context; }
    sub filters { return $_[0]->parent->filters; }

    sub resolve {
        return $_[0]->context->resolve($_[1], defined $_[2] ? $_[2] : ());
    }
    sub stack  { return $_[0]->context->stack($_[1]); }
    sub scopes { return $_[0]->context->scopes; }
    sub scope  { return $_[0]->context->scope; }
    sub merge  { return $_[0]->context->merge($_[1]); }

    #BEGIN { our @ISA = qw[Solution::Template]; }
    sub parse {
        my ($class, $args, $tokens);
        (scalar @_ == 3 ? ($class, $args, $tokens) : ($class, $tokens)) = @_;
        my $self;
        if (ref $class) { $self = $class; }
        else {
            $args->{'nodelist'}
                ||= [];    # XXX - In the future, this may be preloaded?
            $self = bless $args, $class;
        }
    NODE: while (my $token = shift @{$tokens}) {
            if ($token =~ qr[^${Solution::Utility::TagStart}  # {%
                                (.+?)                         # etc
                              ${Solution::Utility::TagEnd}    # %}
                             $]x
                )
            {   my ($tag, $attrs) = (split ' ', $1, 2);

                #warn $tag;
                #use Data::Dump qw[pp];
                #warn pp $self;
                my ($package, $call) = $self->parent->tags->{$tag};
                if ($package
                    && ($call = $self->parent->tags->{$tag}->can('new')))
                {   push @{$self->{'nodelist'}},
                        $call->($package,
                                {parent   => $self->parent,
                                 tag_name => $tag,
                                 markup   => $token,
                                 attrs    => $attrs
                                },
                                $tokens
                        );
                }
                elsif ($self->can('end_tag') && $tag =~ $self->end_tag) {
                    last NODE;
                }
                elsif (   $self->can('conditional_tag')
                       && $tag =~ $self->conditional_tag)
                {   $self->push_block({tag_name => $tag,
                                       attrs    => $attrs,
                                       markup   => $token,
                                       parent   => $self->parent,
                                      },
                                      $tokens
                    );
                }
                else {
                    raise Solution::SyntaxError {
                                          message => 'Unknown tag: ' . $token,
                                          fatal   => 1
                    };
                }
            }
            elsif (
                $token =~ qr
                    [^${Solution::Utility::VariableStart}
                        (.+?)
                        ${Solution::Utility::VariableEnd}
                    $]x
                )
            {   my ($variable, $filters) = split qr[\s*\|\s*], $1, 2;
                my @filters;
                for my $filter (split $Solution::Utility::FilterSeparator,
                                $filters || '')
                {   my ($filter, $args)
                        = split $Solution::Utility::FilterArgumentSeparator,
                        $filter, 2;
                    $filter =~ s[\s*$][]; # XXX - the splitter should clean...
                    $filter =~ s[^\s*][]; # XXX -  ...this up for us.
                    my @args
                        = $args
                        ? split
                        $Solution::Utility::VariableFilterArgumentParser,
                        $args
                        : ();
                    push @filters, [$filter, \@args];
                }
                push @{$self->{'nodelist'}},
                    Solution::Variable->new({parent   => $self,
                                             markup   => $token,
                                             variable => $variable,
                                             filters  => \@filters
                                            }
                    );
            }
            else {
                push @{$self->{'nodelist'}}, $token;
            }
        }
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $return = '';
        for my $node (@{$self->{'nodelist'}}) {
            my $rendering = ref $node ? $node->render() : $node;
            $return .= defined $rendering ? $rendering : '';
        }
        return $return;
    }
}
1;
