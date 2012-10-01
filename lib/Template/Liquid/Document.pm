package Template::Liquid::Document;
{ $Template::Liquid::Document::VERSION = 'v1.0.0' }
use strict;
use warnings;
use lib '../';
use Template::Liquid::Variable;
use Template::Liquid::Utility;
#
sub resolve { $_[0]->template->context->resolve($_[1], $_[2]); }
sub template { $_[0]->{'template'} }
sub parent   { $_[0]->{'parent'} }

#sub context { return $_[0]->{'context'}; }
#sub filters { return $_[0]->{'filters'}; }
#sub resolve {
#    return $_[0]->context->resolve($_[1], defined $_[2] ? $_[2] : ());
#}
#sub stack  { return $_[0]->context->stack($_[1]); }
#sub scopes { return $_[0]->context->scopes; }
#sub scope  { return $_[0]->context->scope; }
#sub merge  { return $_[0]->context->merge($_[1]); }
#BEGIN { our @ISA = qw[Template::Liquid]; }
sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::ContextError {
                                       message => 'Missing template argument',
                                       fatal   => 1
        }
        if !defined $args->{'template'};
    return
        bless {template => $args->{'template'},
               parent   => $args->{'template'}
        }, $class;
}

sub parse {
    my ($class, $args, $tokens);
    (scalar @_ == 3 ? ($class, $args, $tokens) : ($class, $tokens)) = @_;
    my $s = ref $class ? $class : $class->new($args);
NODE: while (my $token = shift @{$tokens}) {
        if ($token =~ qr[^${Template::Liquid::Utility::TagStart}  # {%
                                (.+?)                         # etc
                              ${Template::Liquid::Utility::TagEnd}    # %}
                             $]x
            )
        {   my ($tag, $attrs) = (split ' ', $1, 2);

            my ($package, $call) = $s->template->tags->{$tag};


            if ($package
                && ($call = $s->template->tags->{$tag}->can('new')))
            {   my $_tag =
                    $call->($package,
                            {template => $s->template,
                             parent   => $s,
                             tag_name => $tag,
                             markup   => $token,
                             attrs    => $attrs
                            }
                    );
                push @{$s->{'nodelist'}}, $_tag;
                if ($_tag->conditional_tag) {
                    push @{$_tag->{'blocks'}},
                        Template::Liquid::Block->new(
                                              {tag_name => $tag,
                                               attrs    => $attrs,
                                               template => $_tag->template,
                                               parent   => $_tag
                                              }
                        );
                    $_tag->parse($tokens);
                    {    # finish previous block
                        ${$_tag->{'blocks'}[-1]}{'nodelist'}
                            = $_tag->{'nodelist'};
                        $_tag->{'nodelist'} = [];
                    }
                }
                elsif ($_tag->end_tag) {
                    $_tag->parse($tokens);
                }
            }
            elsif ($s->can('end_tag') && $tag =~ $s->end_tag) {
                $s->{'markup_2'} = $token;
                last NODE;
            }
            elsif (   $s->conditional_tag
                   && $tag =~ $s->conditional_tag)
            {   $s->push_block({tag_name => $tag,
                                   attrs    => $attrs,
                                   markup   => $token,
                                   template => $s->template,
                                   parent   => $s
                                  },
                                  $tokens
                );
            }
            else {
                raise Template::Liquid::SyntaxError 'Unknown tag: ' . $token;
            }
        }
        elsif (
            $token =~ qr[^
                    ${Template::Liquid::Utility::VariableStart} # {{
                        (.+?)                           #  stuff + filters?
                    ${Template::Liquid::Utility::VariableEnd}   # }}
                $]x
            )
        {   my ($variable, $filters) = split qr[\s*\|\s*], $1, 2;
            my @filters;
            for my $filter (split $Template::Liquid::Utility::FilterSeparator,
                            $filters || '')
            {   my ($filter, $args)
                    = split
                    $Template::Liquid::Utility::FilterArgumentSeparator,
                    $filter, 2;
                $filter =~ s[\s*$][];    # XXX - the splitter should clean...
                $filter =~ s[^\s*][];    # XXX -  ...this up for us.
                my @args
                    = $args ?
                    split
                    $Template::Liquid::Utility::VariableFilterArgumentParser,
                    $args
                    : ();
                push @filters, [$filter, \@args];
            }
            push @{$s->{'nodelist'}},
                Template::Liquid::Variable->new(
                                              {template => $s->template,
                                               parent   => $s,
                                               markup   => $token,
                                               variable => $variable,
                                               filters  => \@filters
                                              }
                );
        }
        else {
            push @{$s->{'nodelist'}}, $token;
        }
    }
    return $s;
}

sub render {
    my ($s) = @_;
    my $return = '';
    for my $node (@{$s->{'nodelist'}}) {
        my $rendering = ref $node ? $node->render() : $node;
        $return .= defined $rendering ? $rendering : '';
    }
    return $return;
}
sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }
1;
