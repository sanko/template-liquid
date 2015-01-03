package Solution::Tag::Dump;
{ $Solution::Tag::Dump::VERSION = 'v1.0.3' }
use Carp qw[confess];
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('dump') }

sub new {
    my ($class, $args, $tokens) = @_;
    confess 'Missing template' if !defined $args->{'template'};
    $args->{'attrs'} ||= '.';
    my $s = bless {name     => 'dump-' . $args->{'attrs'},
                   tag_name => $args->{'tag_name'},
                   variable => $args->{'attrs'},
                   template => $args->{'template'},
                   parent   => $args->{'parent'},
    }, $class;
    return $s;
}

sub render {
    my $s   = shift;
    my $var = $s->{'variable'};
    $var
        = $var eq '.'  ? $s->{template}{context}{scopes}
        : $var eq '.*' ? [$s->{template}{context}{scopes}]
        :                $s->{template}{context}->get($var);
    if (eval { require Data::Dump }) {
        return Data::Dump::pp($var);
    }
    else {
        require Data::Dumper;
        return Data::Dumper::Dumper($var);
    }
    return '';
}
1;

=pod

=head1 NAME

Solution::Tag::Dump - Simple Perl Structure Dumping Tag (Functioning Custom Tag Example)

=head1 Synopsis

    {% dump var %}

=head1 Description

This is a dead simple demonstration of
L<extending Template::Liquid|Template::Liquid/"Extending Template::Liquid">.

This tag attempts to use L<Data::Dump> and L<Data::Dumper> to create
stringified versions of data structures...

    use Template::Liquid;
    use Solution::Tag::Dump;
    warn Template::Liquid->parse("{%dump env%}")->render(env => \%ENV);

...or the entire current scope with C<.>...

    use Template::Liquid;
    use Solution::Tag::Include;
    warn Template::Liquid->parse('{%dump .%}')
        ->render(env => \%ENV, inc => \@INC);

...or the entire stack of scopes with C<.*>...

    use Template::Liquid;
    use Solution::Tag::Include;
    warn Template::Liquid->parse('{%for x in (1..1) %}{%dump .*%}{%endfor%}')
        ->render();

=head1 Notes

This is a 5m hack and is subject to change ...I've included no error handling
and it may be completly broken. For a better example, see
L<Solution::Tag::Include>.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Extending Template::Liquid">'s section on
custom tags.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

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
