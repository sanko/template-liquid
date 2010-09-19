package Solution::Variable;
{
    use strict;
    use warnings;
    use lib '../../lib';
    our $MAJOR = 0.0; our $MINOR = 0; our $DEV = -3; our $VERSION = sprintf('%1.3f%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
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
            map { $_ = $self->resolve($_) || $_ } @$args;
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

=pod

=head1 NAME

Solution::Variable - Generic container

=head1 Description

This class can hold just about anything. ...and does. Internally, it's the
basic container for everything. ...for all definitions of 'everything.'

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Solution|Solution/"Create your own filters">'s docs on custom filter creation

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=for git $Id$

=cut
