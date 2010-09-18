package Solution::Variable;
{
    use strict;
    use warnings;
    use lib '../../lib';
    use Solution::Error;
    our @ISA = qw[Solution::Document];

    sub new {
        my ($class, $args) = @_;
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'}
                || !$args->{'template'}->isa('Solution::Template');
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing variable name in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'variable'};
        return bless $args, $class;
    }

    sub render {
        my ($self) = @_;
        my $val = $self->resolve($self->{'variable'});
    FILTER: for my $filter (@{$self->{'filters'}}) {
            my ($name, $args) = @$filter;
            #use Data::Dump;
            #ddx $val, $filter; #, $self->template->context->scope;
            map { $_ = $self->resolve($_)||$_ } @$args;
        PACKAGE: for my $package (@{$self->template->filters}) {
                if (my $call = $package->can($name)) {
                    $val = $call->($val, @$args);
                    next FILTER;
                }
            }
            raise Solution::FilterNotFound $name;
        }
        return join '', @$val      if ref $val eq 'ARRAY';
        return join '', keys %$val if ref $val eq 'HASH';
        return $val;
    }
}
1;
