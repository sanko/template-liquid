package Template::Liquid::Condition;
{ $Template::Liquid::Condition::VERSION = 'v1.0.0' }
use strict;
use warnings;
use lib '../../lib';
use Template::Liquid::Error;
our @ISA = qw[Template::Liquid::Block];

# Makes life easy
use overload 'bool' => \&is_true, fallback => 1;

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::ContextError {
                                       message => 'Missing template argument',
                                       fatal   => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::ContextError {
                                         message => 'Missing parent argument',
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
        return !!(grep {defined} $l, $r) ?
            (grep {m[\D]} $l, $r) ?
            $l eq $r
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
                and (defined $temp{$key} ?
                     _equal($temp{$key}, $l->{$key})
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
        = map { $s->resolve($_) || $_ } ($$s{'lvalue'}, $$s{'rvalue'});
    return !!(grep {defined} $l, $r) ?
        (grep {m[\D]} $l, $r) ?
        $l gt $r
        : $l > $r
        : 0;
}
sub lt { return !$_[0]->gt }

sub contains {
    my ($s) = @_;
    my $l   = $s->resolve($s->{'lvalue'});
    my $r   = quotemeta $s->resolve($s->{'rvalue'});
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
        my $l   = $s->{'lvalue'};
        my $r   = $s->{'rvalue'};
        return (($l && $r) ? 1 : 0);
    }

    sub or {
        my ($s) = @_;
        my $l   = $s->{'lvalue'};
        my $r   = $s->{'rvalue'};
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

=head1 NAME

Template::Liquid::Condition - Basic Relational and Equality Operators

=head1 Description

These operators evaluate to true/false values. This is used internally but
since you're here... might as well skim it. Nothing new to most people.

=head1 Relational Operators

If you're familiar with basic math, you already understand these. Any of these
operators can be combined with binary 'and' and 'or'.

=head2 C<< > >>

Binary operator which returns true if the left argument is numerically less
than the right argument.

Given...

    3 > 4  # false
    4 > 3  # true
    # where x == 10 and y == 12
    x > y  # false
    y > x  # true
    x > 3  # true
    x > x  # false

=head2 C<< < >>

Binary operator which returns true if the left argument is numerically greater
than the right argument.

Given...

    3 < 4   # true
    4 < 3   # false
    # where x == 10 and y == 12
    x < y   # true
    y < x   # false
    x < 30  # true
    x < x   # false

=head2 C<==>

Binary operator which returns true if the left argument is numerically equal
to the right argument.

    # where x == 10 and y == 12
    x == y   # false
    x == 10  # true
    y == y   # true

=head2 C<!=>

Binary operator which returns true if the left argument is numerically not
equal to the right argument.

    # where x == 10 and y == 12
    x != y  # true
    5 != 5  # false

=head2 C<eq>

Binary operator which returns true if the left argument is stringwise equal to
the right argument.

    'test' eq 'test'   # true
    'test' eq 'reset'  # false
    # where x  = 'cool beans'
    x eq 'awesome'     # false
    x eq 'Cool beans'  # false
    x eq 'cool beans'  # true
    x eq x             # true

=head2 C<ne>

Binary operator which returns true if the left argument is stringwise not
equal to the right argument.

    'test' ne 'test'   # false
    'test' ne 'reset'  # true
    # where x  = 'cool beans'
    x ne 'awesome'     # true
    x ne 'Cool beans'  # true
    x ne 'cool beans'  # false
    x ne x             # false

=head2 C<lt>

Binary operator which returns true if the left argument is stringwise less
than the right argument.

    'a' lt 'c'  # true
    'A' lt 'a'  # true
    # where x  = 'q'
    x lt 'r'    # true
    x lt 'm'    # false
    x lt x      # false

=head2 C<gt>

Binary operator which returns true if the left argument is stringwise greater
than the right argument.

    'a' gt 'c'  # false
    'A' gt 'a'  # false
    # where x  = 'q'
    x gt 'r'    # false
    x gt 'm'    # true
    x gt x      # true

=head1 Other Operators

These are nice things to have around...

=head2 C<contains>

The C<contains> operator is context sensitive.

=head3 Strings

If the variable on the left is a string, this operator searches the string
for a pattern match, and (as if in scalar context) returns true if it
succeeds, false if it fails.

Note that this is a simple C<$x =~ qr[${y}]> match. Case matters.

Given...

    # where x = 'The Angels have the police box!'
    x contains 'police'       # true
    x contains 'Police'       # false
    x contains 'police box?'  # false
    x contains 'police box!'  # true
    x contains x              # true

=head3 Lists

If the variable is a list, the operator greps the list to find the attribute.
If found, a true value is returned. Otherwise, the return value is false.

Given...

    # where x = ['one', 'two', 'three']
    x contains 'five'  # false
    x contains 'six'   # false
    x contains 'one'   # true

=head3 Hashes

If the variable is a hash reference, the operator returns true if the
specified element in the hash has ever been initialized, even if the
corresponding value is undefined.

Given...

    # where x = { okay => 'okay', blah => undef }
    x contains 'okay'     # false
    x contains 'alright'  # false
    x contains 'blah'     # true

=head1 Known Bugs

None right now. Give it time.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
