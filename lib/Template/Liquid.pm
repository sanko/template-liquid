package Template::Liquid;
{ $Template::Liquid::VERSION = 'v1.0.0' }
our (%tags, %filters);
#
use Template::Liquid::Document;
use Template::Liquid::Context;
use Template::Liquid::Tag;
use Template::Liquid::Block;
use Template::Liquid::Condition;
sub register_tag { $tags{$_} = scalar caller for @_ }
sub tags {%tags}
use Template::Liquid::Tag::Assign;
use Template::Liquid::Tag::Break;
use Template::Liquid::Tag::Capture;
use Template::Liquid::Tag::Case;
use Template::Liquid::Tag::Comment;
use Template::Liquid::Tag::Continue;
use Template::Liquid::Tag::Cycle;
use Template::Liquid::Tag::For;
use Template::Liquid::Tag::If;
use Template::Liquid::Tag::Raw;
use Template::Liquid::Tag::Unless;
sub register_filter { $filters{$_} = scalar caller for @_ }
sub filters {%filters}

# merge
use Template::Liquid::Filters;
#
sub new {
    my ($class) = @_;
    my $s = bless {break    => 0,
                   continue => 0,
                   tags     => {},
                   filters  => {}
    }, $class;
    return $s;
}

sub parse {
    my ($class, $source) = @_;
    my $s = ref $class ? $class : $class->new();
    my @tokens = Template::Liquid::Utility::tokenize($source);
    $s->{'document'} ||= Template::Liquid::Document->new({template => $s});
    $s->{'document'}->parse(\@tokens);
    return $s;
}

sub render {
    my ($s, $assigns, $info) = @_;
    $info ||= {};
    $info->{'template'} = $s;
    $s->{'context'} = Template::Liquid::Context->new($assigns, $info);
    return $s->{document}->render();
}
1;

=pod

=head1 NAME

Template::Liquid - A Simple, Stateless Template System

=head1 Synopsis

    use Template::Liquid;
    my $template = Template::Liquid->new();
    $template->parse(    # See Template::Liquid::Tag for more examples
          '{% for x in (1..3) reversed %}{{ x }}, {% endfor %}{{ some.text }}'
    );
    print $template->render({some => {text => 'Contact!'}}); # 3, 2, 1, Contact!

=head1 Description

Template::Liquid is a template engine based on Liquid. The Liquid template
engine was crafted for very specific requirements:

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

It's very simple to get started with L<Solution|Solution>. Just as in Liquid,
templates are built and used in two steps: Parse and Render.

    my $sol = Template::Liquid->new();    # Create a Template::Liquid object
    $sol->parse('Hi, {{name}}!');         # Parse and compile the template
    $sol->render({name => 'Sanko'});      # Render the output => "Hi, Sanko!"

    # Or if you're in a hurry...
    Template::Liquid->parse('Hi, {{name}}!')->render({name => 'Sanko'});

The C<parse> step creates a fully compiled template which can be re-used as
often as you like. You can store it in memory or in a cache for faster
rendering later.

All parameters you want Template::Liquid to work with have to be passed as
parameters to the C<render> method. Template::Liquid is a closed ecosystem; it
does not know about your local, instance, global, or environment variables.

For an expanded overview of the Liquid/Solution syntax, please see
L<Template::Liquid::Tag> and read
L<Liquid for Designers|http://wiki.github.com/tobi/liquid/liquid-for-designers>.

=head1 Extending Template::Liquid

Extending the Template::Liquid template engine for your needs is almost too
simple. Keep reading.

=head2 Custom Filters

Filters are simple subs called when needed. They are not passed any state data
by design and must return the modified content.

=for todo I need to write Template::Liquid::Filter which will be POD with all sorts of info in it. Yeah.

=head3 C<< Template::Liquid->register_filter( ... ) >>

This registers a package which Template::Liquid will assume contains one or more
filters.

    # Register a package as a filter
    Template::Liquid->register_filter( 'Template::Solution::Filter::Amalgamut' );

    # Or simply say...
    Template::Liquid->register_filter( );
    # ...and Template::Liquid will assume the filters are in the calling package

=head2 Custom Tags

See the section entitled
L<Extending Template::Liquid with Custom Tags|Template::Liquid::Tag/"Extending Template::Liquid with Custom Tags">
in L<Template::Liquid::Tag> for more information.

To assist with custom tag creation, Template::Liquid provides several basic tag types
for subclassing and exposes the following methods:

=head3 C<< Template::Liquid->register_tag( ... ) >>

This registers a package which must contain (directly or through inheritance)
both a C<parse> and C<render> method.

    # Register a new tag which Template::Liquid will look for in the given package
    Template::Liquid->register_tag( 'newtag', 'Template::Solution::Tag::You're::It' );

    # Or simply say...
    Template::Liquid->register_tag( 'newtag' );
    # ...and Template::Liquid will assume the new tag is in the calling package

Pre-existing tags are replaced when new tags are registered with the same
name. You may want to do this to override some functionality.

For an example of a custom tag, see L<Template::Solution::Tag::Include>.

=head1 Why should I use Template::Liquid?

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

=head1 Why shouldn't I use Template::Liquid?

=over 4

=item * You've found or written a template engine which fills your needs
better than Liquid or Template::Liquid ever could.

=item * You are uncomfortable with text that you didn't copy and paste
yourself. Everyone knows computers cannot be trusted.

=back

=head1 Template::LiquidX or Template::Solution?

I'd really rather use Template::Solution::{Package} for extentions but who
cares? Namespaces are kinda useless if you're the only person using the code.

As I understand it, the original project's name, Liquid, is a reference to the
classical states of matter (the engine itself being stateless). I settled on
L<solution|http://en.wikipedia.org/wiki/Solution> because it's liquid but...
with... bits of other stuff floating in it. (Pretend you majored in chemistry
instead of mathematics or computer science.) Liquid tempates will I<always> be
work with Template::Liquid but (due to Template::Solutions's expanded syntax)
Template::Solution templates I<may not> be compatible with Liquid or
Template::Liquid.

This 'solution' is B<not> the answer to all your problems and obviously not
the only solution for your templating troubles. It's simply I<a> solution.

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

=cut
