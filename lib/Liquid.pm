package Liquid;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.0';
    use Liquid::Document;
    use Liquid::Context;
    use Liquid::Tag;
    use Liquid::Block;
    use Liquid::Condition;
    use Liquid::Template;

    #
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
                      File::Basename::dirname(__FILE__) . '/Liquid/' . $type
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

Liquid - A Simple, Stateless Template System

=head1 Synopsis

    use Liquid;
    my $template = Liquid::Template->new();
    $template->parse(    # See Liquid::Tag for more examples
          '{% for x in (1..3) reversed %}{{ x }}, {% endfor %}{{ some.text }}'
    );
    print $template->render({some => {text => 'Contact!'}}); # 3, 2, 1, Contact!

=head1 Description

L<Liquid|/"'Liquid to what?' or 'Ugh! Why a new Top Level Namespace?'"> is
a template engine based on Liquid. The Liquid template engine was crafted for
very specific requirements:

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

=head1 Getting Started

It's very simple to get started with L<Liquid|Liquid>. Just as in Liquid,
templates are built and used in two steps: Parse and Render.

    my $sol = Liquid::Template->new();  # Create a Liquid::Template object
    $sol->parse('Hi, {{name}}!');         # Parse and compile the template
    $sol->render({name => 'Sanko'});      # Render the output => "Hi, Sanko!"

    # Or if you're in a hurry...
    Liquid::Template->parse('Hi, {{name}}!')->render({name => 'Sanko'});

The C<parse> step creates a fully compiled template which can be re-used as
often as you like. You can store it in memory or in a cache for faster
rendering later.

All parameters you want Liquid to work with have to be passed as parameters
to the C<render> method. Liquid is a closed ecosystem; it does not know
about your local, instance, global, or environment variables.

For an expanded overview of the Liquid/Liquid syntax, please see
L<Liquid::Tag> and read
L<Liquid for Designers|http://wiki.github.com/tobi/liquid/liquid-for-designers>.

=head1 Extending Liquid

Extending the Liquid template engine for your needs is almost too simple.
Keep reading.

=head2 Custom Filters

Filters are simple subs called when needed. They are not passed any state data
by design and must return the modified content.

TODO: I need to write Liquid::Filter which will be POD with all sorts of
info in it. Yeah.

=head3 C<< Liquid->register_filter( ... ) >>

This registers a package which Liquid will assume contains one or more
filters.

    # Register a package as a filter
    Liquid->register_filter( 'LiquidX::Filter::Amalgamut' );

    # Or simply say...
    Liquid->register_filter( );
    # ...and Liquid will assume the filters are in the calling package

=head3 C<< Liquid->filters( ) >>

Returns a list containing all the tags currently loaded for informational
purposes.

=head2 Custom Tags

See the section entitled
L<Extending Liquid with Custom Tags|Liquid::Tag/"Extending Liquid with Custom Tags">
in L<Liquid::Tag> for more information.

To assist with custom tag creation, Liquid provides several basic tag types
for subclassing and exposes the following methods:

=head3 C<< Liquid->register_tag( ... ) >>

This registers a package which must contain (directly or through inheritance)
both a C<parse> and C<render> method.

    # Register a new tag which Liquid will look for in the given package
    Liquid->register_tag( 'newtag', 'LiquidX::Tag::You're::It' );

    # Or simply say...
    Liquid->register_tag( 'newtag' );
    # ...and Liquid will assume the new tag is in the calling package

Pre-existing tags are replaced when new tags are registered with the same
name. You may want to do this to override some functionality.

=head3 C<< Liquid->tags( ) >>

Returns a hashref containing all the tags currently loaded for informational
purposes.

=head1 Why should I use Liquid?

=over 4

=item * You want to allow your users to edit the appearance of your
application, but don't want them to run insecure code on your server.

=item * You want to render templates directly from the database.

=item * You like Smarty-style template engines.

=item * You need a template engine which does HTML just as well as email.

=item * You don't like the markup language of your current template engine.

=item * You wasted three days reinventing this wheel when you could have been
doing something productive like volunteering or catching up on past seasons of
I<Doctor Who>.

=back

=head1 Why shouldn't I use Liquid?

=over 4

=item * You've found or written a template engine which fills your needs
better than Liquid or Liquid ever could.

=item * You are uncomfortable with text that you didn't copy and paste
yourself. Everyone knows computers cannot be trusted.

=back

=head1 'Liquid to what?' or 'Ugh! Why a new Top Level Namespace?'

I really don't have a good reason for claiming a new top level namespace and I
promise to put myself in timeout as punishment.

As I understand it, the original project's name, Liquid, is a reference to the
classical states of matter (the engine itself being stateless). I settled on
L<Liquid|http://en.wikipedia.org/wiki/Liquid> because it's Liquid but...
with... bits of other stuff floating in it. (Pretend you majored in chemistry
instead of mathematics or computer science.) Liquid tempates will I<always> be
work with Liquid but (due to Liquid's expanded syntax) Liquid templates
I<may not> be compatible with Liquid.

This 'Liquid' is B<not> the answer to all your problems and obviously not
the only Liquid for your templating troubles. It's simply I<a> Liquid.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=encoding utf8

The original Liquid template system was developed by
L<jadedPixel|http://jadedpixel.com/> and
L<Tobias Lütke|http://blog.leetsoft.com/>.

=head1 License and Legal

Copyright (C) 2009,2010 by Sanko Robinson <sanko@cpan.org>

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

=for git $Id$

=cut
{
    { package Liquid::Drop; }
    { package Liquid::Extensions; }
    { package Liquid::HTMLTags; }
    { package Liquid::Module_Ex; }
    { package Liquid::Strainer; }
    { package Liquid::Tag::IfChanged; }
}
1;
__END__
Module                            Purpose/Notes              Inheritance
-----------------------------------------------------------------------------------------------------------------------------------------
Liquid                          | [done]                    |
    Liquid::Block               |                           |
    Liquid::Condition           | [done]                    |
    Liquid::Context             | [done]                    |
    Liquid::Document            | [done]                    |
    Liquid::Drop                |                           |
    Liquid::Errors              | [done]                    |
    Liquid::Extensions          |                           |
    Liquid::FileSystem          |                           |
    Liquid::HTMLTags            |                           |
    Liquid::Module_Ex           |                           |
    Liquid::StandardFilters     | [done]                    |
    Liquid::Strainer            |                           |
    Liquid::Tag                 |                           |
        Liquid::Tag::Assign     | [done]                    | Liquid::Tag
        Liquid::Tag::Capture    | [done] extended assign    | Liquid::Tag
        Liquid::Tag::Case       |                           |
        Liquid::Tag::Comment    | [done]                    | Liquid::Tag
        Liquid::Tag::Cycle      |                           |
        Liquid::Tag::For        | [done] for loop construct | Liquid::Tag
        Liquid::Tag::If         | [done] if/elsif/else      | Liquid::Tag
        Liquid::Tag::IfChanged  |                           |
        Liquid::Tag::Include    | [done]                    | Liquid::Tag
        Liquid::Tag::Unless     | [done]                    | Liquid::Tag::If
    Liquid::Template            |                           |
    Liquid::Variable            | [done] echo statement     | Liquid::Document
Liquid::Utility       *         | [temp] Non OO bin         |
