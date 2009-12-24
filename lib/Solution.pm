{

    package Solution;
    use strict;
    use warnings;
    our $VERSION = '0.001';

    #
    use Solution::Document;
    use Solution::Block;
    use Solution::Condition;
    use Solution::Context;
    use Solution::Tag;
    {    # Load all the tags and filters from the standard library
        require File::Find;
        require File::Spec;
        require File::Basename;
        use lib '../';
        File::Find::find(
            {wanted => sub {
                 require $_ if m[(.+)\.pm$];
             },
             no_chdir => 1
            },
            File::Spec->rel2abs(
                          File::Basename::dirname(__FILE__) . '/Solution/Tag/'
            ),
        );
        register_filter('Solution::Filters::Standard');
    }
    my (%tags, @filters);

    sub register_tag {
        $tags{$_[1]} = $_[2] || (caller());
    }
    sub tags { return \%tags }

    sub register_filter {
        my ($name) = @_;            # warn 'Registering filter ' . $name;
        eval qq[require $name;];    # just in case
        push @filters, $name;
    }
    sub filters { return \@filters }
}
1;

=pod

=head1 NAME

Liquid - Simple, Stateless Template System

=head1 Synopsis

    use Liquid;

    my $template = Solution::Template->new( );
    $template->parse(
        '{%for x in (1..3) reversed %}{{x}}, {%endfor%}{{some.text}}'
    );
    print $template->render( { some => { text => 'Contact!' } } );

=head1 Desciption

Liquid is a template engine which was crafted for very specific requirements:

=over 4

=item * It has to have simple markup and beautiful results. Template engines
which don’t produce good looking results are no fun to use.

=item * It needs to be non-evaling and secure. Liquid templates are made so
that users can edit them. You don’t want to run code on your server which your
users wrote.

=item * It has to be stateless. The compile and render steps have to be
separate, so that the expensive parsing and compiling can be done once; later
on, you can just render it by passing in a hash with local variables and
objects.

=item * It needs to be able to style emails as well as HTML.

=back

=head2 Getting Started

It’s very simple to get started with L<Solution|Solution>. Just as in Liquid,
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
application, but don’t want them to run insecure code on your server.

=item * You want to render templates directly from the database.

=item * You like Smarty-style template engines.

=item * You need a template engine which does HTML just as well as emails.

=item * You don’t like the markup language of your current template engine.

=item * You wasted three entire weekends patching this together when you could
have been doing something productive like voulenteering or catching up on
past seasons of I<Dr. Who>.

=back

=head2 Why shouldn't I use Solution?

=over 4

=item * You've found or written your own template engine which fills your
needs better than Liquid ever could.

If you haven't found it yet, check the
L<See Also|Solution/"Other Template Engines"> section.

=item * You eat paste.

=back

=head2 Ugh! Why a new Top Level Namespace?

I really don't have a good reason but I promise to send myself to bed without
dinner as punishment.

Eh... The name L<Solution|Solution> is a reference to the classical states of
matter not an absolute answer. The engine is based on the Liquid Template
Engine in Ruby but with a few extra things tossed it.

=head1 Extending Solution

=head2 Custom Filters

TODO

=head2 Create Your Own Tags

To create a new tag, simply inherit from L<Solution::Tag|Solution::Tag> and
register your block L<globally|Liquid/"register_tag"> or locally with
L<Liquid::Template|Liquid::Template/"register_tag">.

    package SolutionX::Tag::Random;
    use strict;
    use warnings;
    use Carp qw[confess];
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('random') if $Solution::VERSION;

    sub new {
        my ($class, $args, $tokens) = @_;
        $args->{'attrs'} ||= 50;
        my $self = bless {name     => 'rand-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          max      => $args->{'attrs'},
                          parent   => $args->{'parent'},
                          markup   => $args->{'markup'},
        }, $class;
        return $self;
    }

    sub render {
        my ($self) = @_;
        return int rand $self->resolve($self->{'max'});
    }
    1;

Using this new tag is as simple as...

    use Solution;
    use SolutionX::Tag::Random;

    print Solution::Template->parse('{% random max %}')->render({max => 30});

This will print a random integer between C<0> and C<30>.

=head2 Creating Your Own Tag Blocks

Block-like tags are very similar to L<simple|Solution/"Create Your Own Tags">.
Inherit from L<Solution::Tag|Solution::Tag> and register your block
L<globally|Liquid/"register_tag"> or locally with
L<Liquid::Template|Liquid::Template/"register_tag">.

    package SolutionX::Tag::Large::Hadron::Collider;
    use strict;
    use warnings;
    use Carp qw[confess];
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('lhc') if $Solution::VERSION;

    sub new {
        my ($class, $args, $tokens) = @_;
        my $self = bless {name     => 'rand-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          odds     => $args->{'attrs'},
                          parent   => $args->{'parent'},
                          markup   => $args->{'markup'},
                          end_tag  => 'end' . $args->{'tag_name'}
        }, $class;
        $self->parse($tokens);
        return $self;
    }

    sub render {
        my ($self) = @_;
        return if int rand $self->resolve($self->{'odds'});
        return join '', @{$self->{'nodelist'}};
    }
    1;

Using this example tag...

    use Solution;
    use SolutionX::Tag::Large::Hadron::Collider;

    warn Solution::Template->parse(q[{% lhc 2 %}Now, that's money well spent!{% endlhc %}])->render();

Just like the real thing, our C<lhc> tag works only 50% of the time.

The biggest changes between this and the
L<random tag|Solution/"Create Your Own Tags"> we build above are in the
constructor.

The extra C<end_tag> attribute in the object's reference lets the parser know
that this is a block that will slurp until the end tag is found. In our
example, we use C<'end' . $args->{'tag_name'}> because you may eventually
subclass this tag (as SolutionX::Tag::Vehicle::Ford, for example) and let it
inherit this constructor. Now that we're sure the parser knows what to look
for, we go ahead and continue L<parsing|Liquid::Template/"parse"> the list of
tokens. The parser will shove child nodes (L<tags|Solution::Tag>,
L<variables|Solution::Variable>, and simple strings) onto your stack until the
C<end_tag> is found.

In the render step, we must return the strigification of all child nodes
pushed onto the stack by the parser.

=head2 Creating Your Own Tag Blocks

The internals are still kinda rough around this bit so documenting it is on my
TODO list. If you're a glutton for punishment, I guess you can skim the source
for the L<if tag|Solution::Tag::If> and its subclass, the
L<unless tag|Solution::Tag::Unless>.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Solution|Solution/"Create your own filters">'s docs on custom filter creation

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

{

    { package Solution::Drop; }
    { package Solution::Extensions; }
    { package Solution::HTMLTags; }
    { package Solution::Module_Ex; }
    { package Solution::StandardFilters; }
    { package Solution::Strainer; }
    { package Solution::Tag::Case; }
    { package Solution::Tag::Cycle; }
    { package Solution::Tag::IfChanged; }
    { package Solution::Tag::Include; }
    {

        package Solution::Template;
        use strict;
        use warnings;
        use lib 'lib';
        use Solution::Utility;
        sub context { return $_[0]->{'context'} }
        sub filters { return $_[0]->{'filters'} }
        sub tags    { return $_[0]->{'tags'} }
        sub root    { return $_[0]->{'root'} }

        sub new {
            my ($class) = @_;
            my $self = bless {tags    => Solution->tags(),
                              filters => Solution->filters()
            }, $class;
            $self->{'context'} = Solution::Context->new({parent => $self});
            return $self;
        }

        sub parse {
            my ($class, $source) = @_;
            my $self = ref $class ? $class : $class->new();
            my @tokens = Solution::Utility::tokenize($source);
            $self->{'root'}    # XXX - Unless a root is preexisting?
                = Solution::Document->parse({parent => $self}, \@tokens);
            return $self;
        }

        sub render {
            my ($self, $args) = @_;
            return $self->context->stack(
                sub {
                    $self->context->merge($args);
                    return $self->root->render();
                }
            );
        }

        sub register_filter {
            my ($self, $name) = @_;     # warn 'Registering filter ' . $name;
            eval qq[require $name;];    # just in case
             #return @{$self->{'filters'}}{keys %${name}:: } = values %${name}::;
            return push @{$self->{'filters'}}, $name;
        }

        sub register_tag {
            my ($self, $tag_name, $package)
                = @_;                    # warn 'Registering filter ' . $name;
            eval qq[require $package;];  # just in case
            return $self->{'tags'}{$tag_name} = $package;
        }
    }
}
1;
