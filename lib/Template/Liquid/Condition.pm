package Template::Liquid::Condition;
{$Template::Liquid::Condition::VERSION = 'v1.0.0' }
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../lib';
    use Template::Liquid::Error;
    our @ISA = qw[Template::Liquid::Block];

    # Makes life easy
    use overload 'bool' => \&is_true, fallback => 1;

    sub new {
        my ($class, $args) = @_;
        raise Template::Liquid::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        raise Template::Liquid::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        my ($lval, $condition, $rval)
            = ((defined $args->{'attrs'} ? $args->{'attrs'} : '')
               =~ m[("[^"]+"|'[^']+'|(?:[\S]+))]g);
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
            elsif ($condition =~ m[^(?:==|!=|<|>|contains|&&|\|\|)$]) {
                $condition = 'eq'   if $condition eq '==';
                $condition = 'ne'   if $condition eq '!=';
                $condition = 'gt'   if $condition eq '>';
                $condition = 'lt'   if $condition eq '<';
                $condition = '_and' if $condition eq '&&';
                $condition = '_or'  if $condition eq '||';
                return
                    bless {lvalue    => $lval,
                           condition => $condition,
                           rvalue    => $rval,
                           template  => $args->{'template'},
                           parent    => $args->{'parent'}
                    }, $class;
            }
            raise Template::Liquid::ContextError 'Unknown operator ' . $condition;
        }
        return Template::Liquid::ContextError->new(
                            'Bad conditional statement: ' . $args->{'attrs'});
    }
    sub ne { return !$_[0]->eq }    # hashes

    sub eq {
        my ($s) = @_;
        my $l = $s->resolve($s->{'lvalue'})
            || $s->{'lvalue'};
        my $r = $s->resolve($s->{'rvalue'})
            || $s->{'rvalue'};
        return _equal($l, $r);
    }

    sub _equal {    # XXX - Pray we don't have a recursive data structure...
        my ($l, $r) = @_;
        my $ref_l = ref $l;
        return !1 if $ref_l ne ref $r;
        if (!$ref_l) {
            return
                  !!(grep {defined} $l, $r)
                ? (grep {m[\D]} $l, $r)
                    ? $l eq $r
                    : $l == $r
                : !1;
        }
        elsif ($ref_l eq 'ARRAY') {
            return !1 unless scalar @$l == scalar @$r;
            for my $index (0 .. $#{$l}) {
                return !1 if !_equal($l->[$index], $r->[$index]);
            }
            return !!1;
        }
        elsif ($ref_l eq 'HASH') {
            my %temp = %$r;
            for my $key (keys %$l) {
                return 0
                    unless exists $temp{$key}
                        and defined($l->{$key}) eq defined($temp{$key})
                        and (defined $temp{$key}
                             ? _equal($temp{$key}, $l->{$key})
                             : !!1
                        );
                delete $temp{$key};
            }
            return !keys(%temp);
        }
    }

    sub gt {
        my ($s) = @_;
        my ($l, $r)
            = map { $s->resolve($_) || $_ }
            ($$s{'lvalue'}, $$s{'rvalue'});
        return
              !!(grep {defined} $l, $r)
            ? (grep {m[\D]} $l, $r)
                ? $l gt $r
                : $l > $r
            : 0;
    }
    sub lt { return !$_[0]->gt }

    sub contains {
        my ($s) = @_;
        my $l      = $s->resolve($s->{'lvalue'});
        my $r      = quotemeta $s->resolve($s->{'rvalue'});
        return if defined $r && !defined $l;
        return defined($l->{$r}) ? 1 : !1 if ref $l eq 'HASH';
        return (grep { $_ eq $r } @$l) ? 1 : !1 if ref $l eq 'ARRAY';
        return $l =~ qr[${r}] ? 1 : !1;
    }

    sub _and {
        my ($s) = @_;
        my $l = $s->resolve($s->{'lvalue'})
            || $s->{'lvalue'};
        my $r = $s->resolve($s->{'rvalue'})
            || $s->{'rvalue'};
        return (($l && $r) ? 1 : 0);
    }

    sub _or {
        my ($s) = @_;
        my $l = $s->resolve($s->{'lvalue'})
            || $s->{'lvalue'};
        my $r = $s->resolve($s->{'rvalue'})
            || $s->{'rvalue'};
        return (($l || $r) ? 1 : 0);
    }
    {    # Compound inequalities support

        sub and {
            my ($s) = @_;
            my $l      = $s->{'lvalue'};
            my $r      = $s->{'rvalue'};
            return (($l && $r) ? 1 : 0);
        }

        sub or {
            my ($s) = @_;
            my $l      = $s->{'lvalue'};
            my $r      = $s->{'rvalue'};
            return (($l || $r) ? 1 : 0);
        }
    }

    sub is_true {
        my ($s) = @_;
        if (!defined $s->{'condition'} && !defined $s->{'rvalue'}) {
            return !!($s->resolve($s->{'lvalue'}) ? 1 : 0);
        }
        my $condition = $s->can($s->{'condition'});
        raise Template::Liquid::ContextError {
                           message => 'Bad condition ' . $s->{'condition'},
                           fatal   => 1
            }
            if !$condition;

        #return !1 if !$condition;
        return $s->$condition();

}
1;

=pod


=head1 Supported Inequalities

=head2 C<==> / C<eq>

=head2 C<!=> / C<ne>

=head2 C<< > >> / C<< < >>

=head2 C<contains>

=head3 Strings

matches qr[${string}] # case matters

=head3 Lists

grep list

=head3 Hashes

if key exists



=head1 Known Bugs



=cut
