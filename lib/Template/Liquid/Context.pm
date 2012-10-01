package Template::Liquid::Context;
{ $Template::Liquid::Context::VERSION = 'v1.0.0' }
use strict;
use warnings;
use lib '../';
use Template::Liquid::Utility;
use Template::Liquid::Error;
sub scopes    { return $_[0]->{'scopes'} }
sub scope     { return $_[0]->{'scopes'}->[-1] }
sub filters   { return $_[0]->{'filters'} }
sub registers { return $_[0]->{'registers'} }

sub new {
    my ($class, $assigns, $args) = @_;
    return bless {
        filters   => ($args->{'filters'}   ? $args->{'filters'}   : []),
        registers => ($args->{'registers'} ? $args->{'registers'} : {}),
        scopes    => [$assigns             ? $assigns             : {}],
        template => $args->{'template'},    # Required
        errors   => []
    }, $class;
}

sub push {
    my ($s, $context) = @_;
    return raise Template::Liquid::ContextError 'Cannot push new scope!'
        if scalar @{$s->{'scopes'}} == 100;
    return push @{$s->{'scopes'}}, (defined $context ? $context : {});
}

sub pop {
    my ($s) = @_;
    return raise Template::Liquid::ContextError 'Cannot pop scope!'
        if scalar @{$s->{'scopes'}} == 1;
    return pop @{$s->{'scopes'}};
}

sub stack {
    my ($s, $block) = @_;
    my $old_scope = $s->scope;
    $s->push();
    $s->merge($old_scope);
    my $result = $block->($s);
    $s->pop;
    return $result;
}

sub merge {
    my ($s, $new) = @_;
    return $s->{'scopes'}->[0] = __merge(reverse $s->scope, $new);
}

sub _merge {    # Deeply merges data structures
    my ($source, $target) = @_;
    my $return = $target;
    for (keys %$source) {
        if ('ARRAY' eq ref $target->{$_}
            && ('ARRAY' eq ref $source->{$_}
                || !ref $source->{$_})
            )
        {   @{$return->{$_}} = [@{$target->{$_}}, @{$source->{$_}}];
        }
        elsif ('HASH' eq ref $target->{$_}
               && ('HASH' eq ref $source->{$_}
                   || !ref $source->{$_})
            )
        {   $return->{$_} = _merge($source->{$_}, $target->{$_});
        }
        else { $return->{$_} = $source->{$_}; }
    }
    return $return;
}
my $merge_precedent;

sub __merge {    # unless right is more interesting, this is a left-
    my $return = $_[1];    # precedent merge function
    $merge_precedent ||= {
        SCALAR => {SCALAR => sub { defined $_[0] ? $_[0] : $_[1] },
                   ARRAY  => sub { $_[1] },
                   HASH   => sub { $_[1] },
        },
        ARRAY => {
            SCALAR => sub {
                [@{$_[0]}, defined $_[1] ? $_[1] : ()];
            },
            ARRAY => sub { [@{$_[0]}] },
            HASH  => sub { [@{$_[0]}, values %{$_[1]}] },
        },
        HASH => {SCALAR => sub { $_[0] },
                 ARRAY  => sub { $_[0] },
                 HASH   => sub { _merge($_[0], $_[1], $_[2]) },
        }
    };
    for my $key (keys %{$_[0]}) {
        my ($left_ref, $right_ref)
            = map { ref($_->{$key}) =~ m[^(HASH|ARRAY)$] ? $1 : 'SCALAR' }
            ($_[0], $_[1]);

        #warn sprintf '%-12s [%6s|%-6s]', $key, $left_ref, $right_ref;
        $return->{$key} = $merge_precedent->{$left_ref}{$right_ref}
            ->($_[0]->{$key}, $_[1]->{$key});
    }
    return $return;
}

sub resolve {
    my ($s, $path, $val) = @_;
    return if !defined $path;
    return if $path eq '';
    return if $path eq 'null';
    return if $path eq 'nil';
    return if $path eq 'blank';
    return if $path eq 'empty';
    return !1  if $path eq 'false';
    return !!1 if $path eq 'true';
    return $2 if $path =~ m[^(['"])(.+)\1$];
    return [int $s->resolve($1) .. int $s->resolve($2)]
        if $path =~ m[^\((\S+)\.\.(\S+)\)$];    # range
    return $1 if $path =~ m[^(\d+(?:[\d\.]+)?)$];    # int or bad float
    return $s->resolve($1)->[$2] if $path =~ m'^(.+)\[(.+)\]$';
    my @path = split $Template::Liquid::Utility::VariableAttributeSeparator,
        $path;
    my $cursor = \$s->scope;

    while (local $_ = shift @path) {
        my $type = ref $$cursor;
        if ($type eq 'ARRAY') {
            if (scalar @path == 1) {
                return scalar @{$$cursor}    if $path->[0] eq 'size';
                return scalar $$cursor->[0]  if $path->[0] eq 'first';
                return scalar $$cursor->[-1] if $path->[0] eq 'last';
            }
            return unless /^(?:0|[0-9]\d*)\z/;
            if (scalar @path) { $cursor = \$$cursor->[$_]; next; }
            return defined $val ?
                $$cursor->[$_]
                = $val
                : $$cursor->[$_];
        }
        if (@path && $type) { $cursor = \$$cursor->{$_}; next; }

        #warn $$cursor->{$_} if ref  $$cursor->{$_};
        return defined $val ?
            $$cursor->{$_}
            = $val
            : $type ?
            $type eq 'HASH' ?
            $$cursor->{$_}
            : $type eq 'ARRAY' ?
                $$cursor->[$_]
            : $$cursor->can($_) ?
                $$cursor->$_()
            : do { warn 'Cannot call ' . $_; () }
            : defined $$cursor ?
            $$cursor    # die $path . ' is not a hash/array reference'
            : '';
        return $$cursor->{$_};
    }
}
1;

=cut

=head1 NAME

Template::Liquid::Context - Complex Variable Keeper

=head1 Description

This is really only to be used internally.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
