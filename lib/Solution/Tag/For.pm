    package Solution::Tag::For;
    {
        use strict;
        use warnings;
        our $MAJOR = 0.0; our $MINOR = 0; our $DEV = 1; our $VERSION = sprintf('%1.3f%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
        use lib '../../../lib';
        use Solution::Error;
        use Solution::Utility;
        our @ISA = qw[Solution::Tag];
        my $Help_String = 'TODO';
        Solution->register_tag('for', __PACKAGE__) if $Solution::VERSION;

        sub new {
            my ($class, $args) = @_;
            raise Solution::ContextError {
                                       message => 'Missing template argument',
                                       fatal   => 1
                }
                if !defined $args->{'template'};
            raise Solution::ContextError {
                                         message => 'Missing parent argument',
                                         fatal   => 1
                }
                if !defined $args->{'parent'};
            raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
                }
                if !defined $args->{'attrs'};
            if ($args->{'attrs'}
                !~ qr[^([\w\.]+)\s+in\s+(.+?)(?:\s+(.*)\s*?)?$])
            {   raise Solution::SyntaxError {
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
                };
            }
            my ($var, $range, $attr) = ($1, $2, $3 || '');
            my $reversed = $attr =~ s[^reversed\s+?][] ? 1 : 0;
            my %attr = map {
                my ($k, $v)
                    = split $Solution::Utility::FilterArgumentSeparator,
                    $_, 2;
                { $k => $v };
            } split qr[\s+], $attr || '';
            my $self = bless {attributes      => \%attr,
                              collection_name => $range,
                              name            => $var . '-' . $range,
                              nodelist        => [],
                              reversed        => $reversed,
                              tag_name        => $args->{'tag_name'},
                              variable_name   => $var,
                              end_tag         => 'end' . $args->{'tag_name'},
                              template        => $args->{'template'},
                              parent          => $args->{'parent'},
                              markup          => $args->{'markup'}
            }, $class;
            return $self;
        }

        sub render {
            my ($self)   = @_;
            my $range    = $self->{'collection_name'};
            my $attr     = $self->{'attributes'};
            my $reversed = $self->{'reversed'};
            my $offset
                = defined $attr->{'offset'}
                ? $self->resolve($attr->{'offset'})
                : ();
            my $limit
                = defined $attr->{'limit'}
                ? $self->resolve($attr->{'limit'})
                : ();
            my $list = $self->resolve($range) || [];
            {    # Break it down to only the items we plan on using
                my $min = (defined $offset ? $offset : 0);
                my $max = (defined $limit
                           ? $limit + (defined $offset ? $offset : 0) - 1
                           : $#$list
                );
                $max    = $#$list if $max > $#$list;
                @$list  = @{$list}[$min .. $max];
                @$list  = reverse @$list if $reversed;
                $limit  = defined $limit ? $limit : scalar @$list;
                $offset = defined $offset ? $offset : 0;
            }
            return $self->template->context->stack(
                sub {
                    my $return = '';
                    my $nodes  = $self->{'nodelist'};
                    my $steps  = $#$list;
                    for my $index (0 .. $steps) {
                        $self->template->context->scope
                            ->{$self->{'variable_name'}} = $list->[$index];
                        $self->template->context->scope->{'forloop'} = {
                                        length => $steps + 1,
                                        limit  => $limit,
                                        offset => $offset,
                                        name   => $self->{'name'},
                                        first  => ($index == 0 ? !!1 : !1),
                                        last => ($index == $steps ? !!1 : !1),
                                        index   => $index + 1,
                                        index0  => $index,
                                        rindex  => $steps - $index + 1,
                                        rindex0 => $steps - $index,
                        };
                        for my $node (@$nodes) {
                            my $rendering
                                = ref $node ? $node->render() : $node;
                            $return .= defined $rendering ? $rendering : '';
                        }
                    }
                    return $return;
                }
            );
        }
    }
    1;

=pod

=head1 NAME

Solution::Tag::For - Simple loop construct

=head1 Synopsis

    {% for x in (1..10) %}
        x = {{ x }}
    {% endfor %}

=head1 Description

L<Liquid|Liquid> allows for loops over collections.

=head2 Loop-scope Variables

During every for loop, the following helper variables are available for extra
styling needs:

=over

=item * C<forloop.length>

length of the entire for loop

=item * C<forloop.index>

index of the current iteration

=item * C<forloop.index0>

index of the current iteration (zero based)

=item * C<forloop.rindex>

how many items are still left?

=item * C<forloop.rindex0>

how many items are still left? (zero based)

=item * C<forloop.first>

is this the first iteration?

=item * C<forloop.last>

is this the last iternation?

=back

=head2 Attributes

There are several attributes you can use to influence which items you receive
in your loop:

=over

=item C<limit:int>

lets you restrict how many items you get.

=item C<offset:int>

lets you start the collection with the nth item.

=back

    # array = [1,2,3,4,5,6]
    {% for item in array limit:2 offset:2 %}
        {{ item }}
    {% endfor %}
    # results in 3,4

=head3 Reversing the Loop

You can reverse the direction the loop works with the C<reversed> attribute.
To comply with the Ruby lib's functionality, C<reversed> B<must> be the first
attribute.

    {% for item in collection reversed %} {{item}} {% endfor %}

=head2 Numeric Ranges

Instead of looping over an existing collection, you can define a range of
numbers to loop through. The range can be defined by both literal and variable
numbers:

    # if item.quantity is 4...
    {% for i in (1..item.quantity) %}
        {{ i }}
    {% endfor %}
    # results in 1,2,3,4

=head1 TODO

Since this is a customer facing template engine, Liquid should provide some
way to limit L<ranges|Solution::Tag::For/"Numeric Ranges"> and/or depth to avoid
(functionally) infinite loops with code like...

    {% for w in (1..10000000000) %}
        {% for x in (1..10000000000) %}
            {% for y in (1..10000000000) %}
                {% for z in (1..10000000000) %}
                    {{ 'own' | replace:'o','p' }}
                {%endfor%}
            {%endfor%}
        {%endfor%}
    {%endfor%}

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
