{

    package Solution;
    use strict;
    use warnings;
    our $VERSION = '0.001';

    #
    use Solution::Document;
    use Solution::Block;
    use Solution::Condition;
    use Solution::Tag;

    sub import {

        # Load all the tags and filters from the standard library
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

=head2 Why should I use Liquid?

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

=head2 Why shouldn't I use Liquid?

=over 4

=item * You've found or written your own template engine which fills your
needs better than Liquid ever could.

If you haven't found it yet, check the
L<See Also|Solution/"Other Template Engines"> section.

=item * You eat paste.

=back

=head2 Why a new Top Level Namespace?

I really don't have a good reason but I promise to send myself to bed without
dinner as punishment.

Eh... The name L<Solution|Solution> is a reference to the classical states of
matter not an absolute answer. The engine is based on the Liquid Template
Engine in Ruby but with a few extra things tossed it.

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
    {

        package Solution::Context;
        use strict;
        use warnings;
        use lib 'lib';
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
                else {
                    $target->{$_} = $source->{$_};
                }
            }
        }

        sub resolve {
            my ($self, $path, $val) = @_;    # warn '### Resolving ' . $path;
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
