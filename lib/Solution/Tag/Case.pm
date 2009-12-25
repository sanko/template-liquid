package Solution::Tag::Case;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag::If];
    Solution->register_tag('case') if $Solution::VERSION;

    sub new {
        my ($class, $args, $tokens) = @_;
        raise Solution::ContextError {message => 'Missing root argument',
                                      fatal   => 1
            }
            if !defined $args->{'root'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'};
        if ($args->{'attrs'} !~ m[\S$]) {
            raise Solution::SyntaxError {
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
            };
        }
        my $self = bless {
                         name => $args->{'tag_name'} . '-' . $args->{'attrs'},
                         blocks          => [],
                         tag_name        => $args->{'tag_name'},
                         root            => $args->{'root'},
                         parent          => $args->{'parent'},
                         markup          => $args->{'markup'},
                         value           => $args->{'attrs'},
                         end_tag         => 'end' . $args->{'tag_name'},
                         conditional_tag => qr[^(?:else|when)$]
        }, $class;
        $self->parse($tokens);
        {    # finish final block
            ${$self->{'blocks'}[-1]}{'nodelist'} = $self->{'nodelist'};
            $self->{'nodelist'} = [];
        }
        return $self;
    }

    sub push_block {
        my ($self, $args, $tokens) = @_;
        raise Solution::ContextError {message => 'Missing root argument',
                                      fatal   => 1
            }
            if !defined $args->{'root'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'} && $args->{'tag_name'} eq 'when';
        if (scalar @{$self->{'blocks'}}) {    # finish previous block
            ${$self->{'blocks'}[-1]}{'nodelist'} = $self->{'nodelist'};
        }
        $self->{'nodelist'} = [];    # Unline {%if%}, we *always* empty the
             # nodelist. This way, we ignore nodes that come before the first
             # when/else block just like Liquid
        if ($args->{'tag_name'} eq 'when') {
            $args->{'attrs'}
                = join ' or ',
                map { sprintf '%s == %s', $_, $args->{'parent'}{'value'} }
                grep { defined $_ }
                $args->{'attrs'} =~ m[(${Solution::Utility::Expression})
                        (?:(?:\s+or\s+|\s*\,\s*)
                           (${Solution::Utility::Expression}.*)
                        )?]x;
        }
        push @{$self->{'blocks'}},
            Solution::Block->new({tag_name => $args->{'tag_name'},
                                  end_tag  => 'end' . $args->{'tag_name'},
                                  attrs    => $args->{'attrs'},
                                  root     => $args->{'root'},
                                  parent   => $self
                                 },
                                 $tokens
            );
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Case - Switch Statement Construct

=head1 Description

If you need more conditions, you can use the C<case> tag. Note that, stuff
that comes before the first C<when> or C<else> is ignored. ...just as it is in
Liquid.

=head1 Synopsis

    {% case condition %}
        {% when 1 %}
            hit 1
        {% when 2 or 3 %}
            hit 2 or 3
        {% else %}
            ... else ...
    {% endcase %}

...or even...

    {% case template %}

        {% when 'label' %}
            // {{ label.title }}
        {% when 'product' %}
            // {{ product.vendor | link_to_vendor }} / {{ product.title }}
        {% else %}
            // {{page_title}
    {% endcase %}

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

=cut
