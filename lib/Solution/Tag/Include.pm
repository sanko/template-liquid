package Solution::Tag::Include;
{
    use strict;
    use warnings;
    our $MAJOR = 0.0; our $MINOR = 0; our $DEV = -2; our $VERSION = sprintf('%1.3f%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    use File::Spec;
    BEGIN { our @ISA = qw[Solution::Tag]; }
    Solution->register_tag('include', __PACKAGE__) if $Solution::VERSION;

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
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'};
        return
            bless {name     => 'inc-' . $args->{'attrs'},
                   file     => $args->{'attrs'},
                   parent   => $args->{'parent'},
                   template => $args->{'template'},
                   tag_name => $args->{'tag_name'},
                   markup   => $args->{'markup'},
            }, $class;
    }

    sub render {
        my ($self) = @_;
        my $file = $self->resolve($self->{'file'});
        return 'Error: Missing template argument' if !defined $file;
        if (   $file !~ m[^[\w\\/\.-_]+$]i
            || $file =~ m[\.[\\/]]
            || $file =~ m[[//\\]\.])
        {   return
                sprintf
                q[Error: Include file '%s' contains invalid characters or sequiences],
                $file;
        }
        $file = File::Spec->catdir(

            # $self->template->context->registers->{'site'}->source,
            '_includes',
            $file
        );
        return sprintf 'Error: Included file %s not found', $file
            if !-f $file;
        open(my ($FH), '<', $file)
            || return sprintf 'Error: Cannot include file %s: %s',
            $file, $!;
        sysread($FH, my ($DATA), -s $FH) == -s $FH
            || return
            sprintf
            'Error: Cannot include file %s (Failed to read %d bytes): %s',
            $file, -s $FH, $!;
        my $partial = Solution::Template->parse($DATA);
        $partial->{'context'} = $self->template->context;
        my $return = $partial->context->stack(sub { $partial->render(); });
        return $return;
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Include - Include another file

=head1 Synopsis

    {% include 'somefile.inc %}

=head1 Description

If you find yourself using the same snippet of code or text in several
templates, you may consider making the snippet an include.

You include static filenames...

   Solution::Template->parse("{%include 'my.inc'%}")->render();

...or 'dynamic' filenames (for example, based on a variable)...

    Solution::Template->parse('{%include inc%}')->render({inc => 'my.inc'});

=head1 Notes

As long as the file is in the C<./_includes/> directory. This location
restriction may go away in the future but for now, I'll mimic Jekyll (github's
Liquid-based template system).

This is a 15m hack and is subject to change ...and may be completly broken.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Liquid|Liquid/"Create your own filters">'s docs on custom filter creation

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
