package Solution::Context;
{
    use strict;
    use warnings;
    use lib '../';
    our $VERSION = 0.001;
    use Solution::Utility;
    use Solution::Error;
    sub scopes { return $_[0]->{'scopes'} }
    sub scope  { return $_[0]->scopes->[-1] }

    sub new {
        my ($class, $args) = @_;
        $args->{'scopes'} = [{}];
        return bless $args, $class;
    }

    sub push {
        my ($self) = @_;
        return raise Solution::ContextError 'Cannot push new scope!'
            if scalar @{$self->{'scopes'}} == 100;
        return push @{$self->{'scopes'}}, {};
    }

    sub pop {
        my ($self) = @_;
        return raise Solution::ContextError 'Cannot pop scope!'
            if scalar @{$self->{'scopes'}} == 1;
        return pop @{$self->{'scopes'}};
    }

    sub stack {
        my ($self, $block) = @_;
        $self->push;
        my $result = $block->($self);
        $self->pop;
        return $result;
    }

    sub merge {
        my ($self, $new) = @_;
        return _merge($new, $self->scope);
    }

    sub _merge {    # Deeply merges data structures
        my ($source, $target) = @_;
        for (keys %$source) {
            if ('ARRAY' eq ref $target->{$_}
                && ('ARRAY' eq ref $source->{$_}
                    || !ref $source->{$_})
                )
            {   CORE::push @{$target->{$_}}, @{$source->{$_}};
            }
            elsif ('HASH' eq ref $target->{$_}
                   && ('HASH' eq ref $source->{$_}
                       || !ref $source->{$_})
                )
            {   _merge($source->{$_}, $target->{$_});
            }
            else { $target->{$_} = $source->{$_}; }
        }
    }

    sub resolve {
        my ($self, $path, $val) = @_;    # warn '### Resolving ' . $path;
        raise Solution::ArgumentError 'Cannot resolve empty/undefined path'
            if !defined $path;
        return !1    if $path eq 'false';
        return !!1   if $path eq 'true';
        return undef if $path eq 'null';
        return $2 if $path =~ m[^(['"])(.+)\1$];
        return $1 if $path =~ m[^(\d+)$];
        my $cursor = \$self->scope;
        my @path   = split $Solution::Utility::VariableAttributeSeparator,
            $path;

        while (local $_ = shift @path) {
            my $type = ref $$cursor;
            if ($type eq 'ARRAY') {
                return () unless /^(?:0|[0-9]\d*)\z/;
                if (@path) { $cursor = \$$cursor->[$_]; next; }
                return defined $val
                    ? $$cursor->[$_]
                    = $val
                    : $$cursor->[$_];
            }
            if (@path && $type) { $cursor = \$$cursor->{$_}; next; }
            return defined $val
                ? $$cursor->{$_}
                = $val
                : $type ? $type eq 'HASH'
                    ? $$cursor->{$_}
                    : $$cursor->[$_]
                : defined $$cursor
                ? confess $path . ' is not a hash/array reference'
                : '';
            return $$cursor->{$_};
        }
    }
}
1;
