package Solution;
{
    use strict;
    use warnings;
    our $MAJOR = 0.0; our $MINOR = 0; our $DEV = 1; our $VERSION = sprintf('%1.3f%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);

    #
    use Solution::Document;
    use Solution::Block;
    use Solution::Condition;
    use Solution::Context;
    use Solution::Tag;
    use Solution::Template;
    {    # Load all the tags from the standard library
        require File::Find;
        require File::Spec;
        require File::Basename;
        use lib '../';
        for my $type (qw[Tag Filter]) {
            File::Find::find(
                {wanted => sub {
                     require $_ if m[(.+)\.pm$];
                 },
                 no_chdir => 1
                },
                File::Spec->rel2abs(
                      File::Basename::dirname(__FILE__) . '/Solution/' . $type
                )
            );
        }
    }
    my (%tags, @filters);
    sub register_tag { $tags{$_[1]} = $_[2] ? $_[2] : scalar caller }
    sub tags { return \%tags }
    sub register_filter { push @filters, $_[1] ? $_[1] : scalar caller }
    sub filters { return \@filters }
}
1;

=pod

=head1 NAME

Solution - Simple, Stateless Template System

=head1 Synopsis

    use Solution;

    my $template = Solution::Template->new( );
    $template->parse(
        '{%for x in (1..3) reversed %}{{x}}, {%endfor%}{{some.text}}'
    );
    print $template->render( { some => { text => 'Contact!' } } );

=head1 Description

Solution is a template engine which was crafted for very specific
requirements:

=over 4

=item * It has to have simple markup and beautiful results. Template engines
which don't produce good looking results are no fun to use.

=item * It needs to be non-evaling and secure. Liquid templates are made so
that users can edit them. You don't want to run code on your server which your
users wrote.

=item * It has to be stateless. The compile and render steps have to be
separate, so that the expensive parsing and compiling can be done once; later
on, you can just render it by passing in a hash with local variables and
objects.

=item * It needs to be able to style emails as well as HTML.

=back

=head2 Getting Started

It's very simple to get started with L<Solution|Solution>. Just as in Liquid,
templates are built and used in two steps: Parse and Render.

For an overview of the Liquid/Solution syntax, please read
Liquid for Designers (it's linked to in the L<See Also|Solution/"See Also">
section below).

    # Parses and compiles the template
    my $template = Solution::Template->parse('Hi, {{name}}!');

    # Renders the output => "Hi, Sanko!"
    $template->render({ name => 'Sanko' });

The C<parse> step creates a fully compiled template which can be re-used as
often as you like. You can store it in memory or in a cache for faster
rendering later.

All parameters you want L<Solution> to work with have to be passed as
parameters to the render method. L<Solution> is a closed ecosystem; it does
not know about your local, instance, and global variables.

=head2 Why should I use Solution?

=over 4

=item * You want to allow your users to edit the appearance of your
application, but don't want them to run insecure code on your server.

=item * You want to render templates directly from the database.

=item * You like Smarty-style template engines.

=item * You need a template engine which does HTML just as well as emails.

=item * You don't like the markup language of your current template engine.

=item * You wasted three days patching this together when you could have been
doing something productive like volunteering or catching up on past seasons of
I<Dr. Who>.

=back

=head2 Why shouldn't I use Solution?

=over 4

=item * You've found or written your own template engine which fills your
needs better than Liquid or Solution ever could.

Psst! Hey, if you haven't found it yet, check the
L<See Also|Solution/"Other Template Engines"> section.

=item * You eat paste.

=back

=head2 Ugh! Why a new Top Level Namespace?

I really don't have a good reason but I promise to send myself to bed without
dinner as punishment.

As I understand it, the original Ruby project's name, Liquid, is a reference
to the classical states of matter. The engine is stateless. ...okay, so maybe
there's a little reaching. Anyway, I settled on L<Solution|Solution> because
it's the Liquid Template Engine but with... stuff floating in it. Yeah,
pretend you majored in chemistry instead of mathematics. This solution is the
answer to all your various problems. ...or any of them, actually.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Solution::Tag|Solution::Tag/"Create your own filters">'s docs on custom filter creation

=head2 Other Template Engines

=over

=item * The L<Template Toolkit|Template> is the granddaddy of all Perl based
template engines.

=item * ...which would make L<Template::Tiny|Template::Tiny> the weird uncle.

=back

I<Note: This list is incomplete.>

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009,2010 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

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

{
    { package Solution::Drop; }
    { package Solution::Extensions; }
    { package Solution::HTMLTags; }
    { package Solution::Module_Ex; }
    { package Solution::Strainer; }
    { package Solution::Tag::IfChanged; }
    { package Solution::Tag::Include; }
}
1;
