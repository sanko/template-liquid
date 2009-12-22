package Liquid::Variable;
{
    use strict;
    use warnings;
    use lib '../../lib';
    use Liquid::Error;
    BEGIN { our @ISA = qw[Liquid::Document]; }
    sub variable { return $_[0]->{'variable'} }

    sub new {
        my ($class, $args) = @_;
        raise Liquid::ContextError {message => 'Missing parent argument',
                                    fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Liquid::SyntaxError {
                   message => 'Missing variable name in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'variable'};
        return bless $args, $class;
    }

    sub render {
        my ($self) = @_;
        my $value = $self->parent->parent->context->resolve($self->variable);

        # XXX - Duplicated in Liquid::Tag::Assign
    FILTER: for my $filter (@{$self->{'filters'}}) {
            my ($name, $args) = @$filter;
            map { $_ = m[^(['"])(.+)\1\s*$] ? $2 : $self->resolve($_) }
                @$args;
        PACKAGE: for my $package (@{$self->root->filters}) {
                if (my $call = $package->can($name)) {
                    $value = $call->($value, @$args);
                    next FILTER;
                }
                else {
                    raise Liquid::FilterNotFound $name;
                }
            }
        }
        return join '', @$value      if ref $value eq 'ARRAY';
        return join '', keys %$value if ref $value eq 'HASH';
        return $value;
    }
}
1;
