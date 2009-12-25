package Solution::Condition;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../lib';
    use Solution::Error;

    #
    our @ISA = qw[Solution::Block];

    # Makes life easy
    use overload 'bool' => \&is_true, fallback => 1;

    sub new {
        my ($class, $args) = @_;
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        my ($lval, $condition, $rval)
            = (($args->{'attrs'} || '') =~ m[("[^"]+"|'[^']+'|(?:[\S]+))]g);
        if (defined $lval) {
            if (!defined $rval && !defined $condition) {
                return
                    bless {lvalue    => $lval,
                           condition => undef,
                           rvalue    => undef,
                           template  => $args->{'template'},
                           parent    => $args->{'parent'}
                    }, $class;
            }
            elsif ($condition =~ m[^(?:==|!=|<|>|contains)$]) {
                $condition = 'eq' if $condition eq '==';
                $condition = 'ne' if $condition eq '!=';
                $condition = 'gt' if $condition eq '>';
                $condition = 'lt' if $condition eq '<';
                return
                    bless {lvalue    => $lval,
                           condition => $condition,
                           rvalue    => $rval,
                           template  => $args->{'template'},
                           parent    => $args->{'parent'}
                    }, $class;
            }
        }
        raise Solution::ContextError {
                  message => 'Bad conditional statement: ' . $args->{'attrs'},
                  fatal   => 1
        };
    }

    sub eq {
        my ($self) = @_;
        my ($l, $r)
            = map { $self->template->context->resolve($_) || $_ }
            ($$self{'lvalue'}, $$self{'rvalue'});
        return
              !!(grep {defined} $l, $r)
            ? (grep {m[\D]} $l, $r)
                ? $l eq $r
                : $l == $r
            : 0;
    }
    sub ne { return !$_[0]->eq }

    sub gt {
        my ($self) = @_;
        my ($l, $r)
            = map { $self->template->context->resolve($_) || $_ }
            ($$self{'lvalue'}, $$self{'rvalue'});
        return
              !!(grep {defined} $l, $r)
            ? (grep {m[\D]} $l, $r)
                ? $l gt $r
                : $l > $r
            : 0;
    }
    sub lt { return !$_[0]->gt }

    sub contains {
        my ($self) = @_;
        my $l      = $self->template->context->resolve($self->{'lvalue'});
        my $r      = quotemeta $self->template->context->resolve($self->{'rvalue'});
        return if defined $r && !defined $l;
        return $l =~ qr[${r}] ? 1 : !1;
    }

    sub and {
        my ($self) = @_;
        my $l      = $self->{'lvalue'};
        my $r      = $self->{'rvalue'};
        return (($l && $r) ? 1 : 0);
    }

    sub or {
        my ($self) = @_;
        my $l      = $self->{'lvalue'};
        my $r      = $self->{'rvalue'};
        return (($l || $r) ? 1 : 0);
    }

    sub is_true {
        my ($self) = @_;
        if (!defined $self->{'condition'} && !defined $self->{'rvalue'}) {
            return !!(
                $self->template->context->resolve($self->{'lvalue'}) ? 1 : 0);
        }
        my $condition = $self->can($self->{'condition'});
        raise Solution::ContextError {
                           message => 'Bad condition ' . $self->{'condition'},
                           fatal   => 1
            }
            if !$condition;

        #return !1 if !$condition;
        return $self->$condition();
    }
}
1;
