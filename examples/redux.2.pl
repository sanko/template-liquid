use strict;
use warnings;
$|++;
use Carp;

# Utility
$Carp::INTERNAL{'main'}++;

sub pp {
    if (eval { require Data::Dump }) {
        carp Data::Dump::pp(+shift);
    }
    else {
        require Data::Dumper;
        carp Data::Dumper::Dumper(shift);
    }
}
{

    package Liquid;
    use strict;
    use warnings;
BEGIN {

        # Basic regex
        our $FilterSeparator            = qr[\|];
        our $ArgumentSeparator          = qr[,];
        our $FilterArgumentSeparator    = qr[:];
        our $VariableAttributeSeparator = qr[\.];
        our $TagStart                   = qr[\{\%];
        our $TagEnd                     = qr[\%\}];
        our $VariableSignature          = qr[\(?[\w\-\.\[\]]\)?];
        our $VariableSegment            = qr[[\w\-]\??]x;
        our $VariableStart              = qr/\{\{/;
        our $VariableEnd                = qr/\}\}/;
        our $VariableIncompleteEnd      = qr/\}\}?/;
        our $QuotedString               = qr/"[^"]+"|'[^']+'/;
        our $QuotedFragment
            = qr/${QuotedString}|(?:[^\s,\|'"]|${QuotedString})+/;
        our $StrictQuotedFragment = qr/"[^"]+"|'[^']+'|[^\s,\|,\:,\,]+/;
        our $FirstFilterArgument
            = qr/${FilterArgumentSeparator}(?:${StrictQuotedFragment})/;
        our $OtherFilterArgument
            = qr/${ArgumentSeparator}(?:${StrictQuotedFragment})/;
        our $SpacelessFilter
            = qr/${FilterSeparator}(?:${StrictQuotedFragment})(?:${FirstFilterArgument}(?:${OtherFilterArgument})*)?/;
        our $Expression    = qr/(?:${QuotedFragment}(?:${SpacelessFilter})*)/;
        our $TagAttributes = qr/(\w+)\s*\:\s*(${QuotedFragment})/;
        our $AnyStartingTag = qr/\{\{|\{\%/;
        our $PartialTemplateParser
            = qr/${TagStart}.*?${TagEnd}|${VariableStart}.*?${VariableIncompleteEnd}/;
        our $TemplateParser
            = qr[(${PartialTemplateParser}|${AnyStartingTag})];
        our $VariableParser = qr/\[[^\]]+\]|${VariableSegment}+/;
    }
}
{

    package Liquid::Template;
    use strict;
    use warnings;

    BEGIN {
        our $Tags = {if => 'Template::Tag::If'};
    }

=pod

=head1 NAME

Liquid::Template - Blah

=head1 Synopsis


    $template = Liquid::Template->parse( $source );
    $template->render( {'user_name' => 'bob'} );

=head1 Description

Templates are central to liquid.

Interpretating templates is a two step process. First you compile the source
code you got. During compile time some extensive error checking is performed.

Your code should expect to get some
L<SyntaxErrors|Liquid::Errors/"SyntaxErrors">.

After you have a compiled template you can then
L<render|Liquid::Template/"render"> it. You can use a compiled template over
and over again and keep it cached.

=head1 Methods

=cut

    sub new {

        # Creates a new L<Template|Liquid::Template> from an array of tokens.
        # Use L<Liquid::Template->parse|Liquid:Template/"parse"> instead.
        my ($class, $source) = @_;
        return
            bless \{tags      => {},
                    errors    => [],
                    registers => {},
                    assigns   => {},
                    root      => undef,
            }, $class;
    }

    sub file_system {
        my ($self, $obj) = @_;
        return $obj ? $self->{'file_system'} = $obj : $self->{'file_system'};
    }

    sub register_tag {
        my ($self, $name, $class) = @_;
        $self->{'tags'}{$name} = $class;
    }
    sub tags { return %{$_[0]->{'tags'} || {}} }

    sub register_filter {
        my ($self, $mod) = @_;

        # Pass a module with filter methods which should be available to all
        # liquid views. Good for registering the standard library
        return $self->strainer->global_filter($mod);
    }

    sub parse {

   # Creates a new L<Template|Liquid::Template> object from liquid source code
        my ($self, $source) = @_;
        my $template = $self->new();
        $template->_parse($source);
        return $template;
    }

    # Parse source code.
    # Returns self for easy chaining
    sub _parse {
        my ($self, $source) = @_;
        main::pp _tokenize($source);
        $$$self{'root'} = Liquid::Document->new(_tokenize($source));
        return $self;
    }

    sub registers {
        my ($self) = @_;
        return $$$self{'registers'};
    }

    sub assigns {
        my ($self) = @_;
        return $$$self{'assigns'};
    }

    sub errors {
        my ($self) = @_;
        return $$$self{'errors'};
    }

=pod

=head2 C<render>

Render takes a hash with local variables.

If you use the same filters over and over again consider registering them
globally with L<register_filter|Liquid::Template/"register_filter">.

The following options can be passed:

=over

=item * C<filters>

An array with local filters.

=item * C<registers>

A hash with register variables. Those can be accessed from filters and tags
and might be useful to integrate liquid more with its host application.

=back

=cut
    sub render { die 'TODO!!!' }

    sub _tokenize {

   # Uses the C<$Liquid::TemplateParser> regexp to tokenize the passed source.
        my ($source) = @_;
        $source = $source->source() if ref $source && $source->can('source');
        return [] if !$source;
        my @tokens = split $Liquid::TemplateParser, $source;

        # removes the rogue empty element at the beginning of the array
        shift @tokens if defined $tokens[0] && !length $tokens[0];
        return \@tokens;
    }
}
{

    package Liquid::Document;
    use strict;
    use warnings;
    BEGIN { our @ISA = qw[Liquid::Block]; }

    sub new {
        my ($class, $tokens) = @_;
        my $self = bless \{tokens => $tokens}, $class;
        warn 'BEFORE';
        $self->parse($tokens);
        warn 'AFTER';
        return $self;
    }

    sub block_delimiter {

        # There isn't a real delimiter
        return [];
    }

    sub assert_missing_delimitation {

# Document blocks don't need to be terminated since they are not actually opened
    }
}
{

    package Liquid::Block;
    use strict;
    use warnings;

    sub parse {
        my ($self, $tokens) = @_;
        $$$self{'nodelist'} ||= [];
        while (my $token = shift @$tokens) {
            if ($token =~ m[^${Liquid::TagStart}]) {
                warn 'START!';
                if ($token
                    =~ m[^${Liquid::TagStart}\s*(\w+)\s*(.*)?${Liquid::TagEnd}$]
                    )
                {   my ($tag, $value) = ($1, $2);

# if we found the proper block delimitor just end parsing here and let the outer block
# proceed
                    if ($self->block_delimiter() eq $tag) {
                        warn 'BLOCK_DELIMITER!';
                        $self->end_tag();
                        return;
                    }

                    # fetch the tag from registered blocks
                    if ($Liquid::Template::Tags->{$1}) {
                        push @{$$$self{'nodelist'}},
                            Liquid::Template::Tags->new($1, $2, $tokens);
                    }
                    else {

        # this tag is not registered with the system
        # pass it to the current block for special handling or error reporting
                        warn sprintf 'Unknown Tag: %s( %s )', $tag, $value;

                        #$self->unknown_tag($1, $2, $tokens);
                    }
                }
                else {
                    warn 'SYNTAXERROR';

#raise SyntaxError, "Tag '#{token}' was not properly terminated withregexp: #{TagEnd.inspect} ";
                }
            }
            elsif ($token =~ m[^${Liquid::VariableStart}]) {
                warn 'VARIABLE';
                push @{$$$self{'nodelist'}}, create_variable($token);
            }
            elsif ($token eq '') {
                warn 'EMPTY TOKEN';

                # pass
            }
            else {
                warn 'PLIAN TOKEN!';
                push @{$self->{'nodelist'}}, $token;
            }
        }

# Make sure that its ok to end parsing in the current block.
# Effectively this method will throw and exception unless the current block is
# of type Document
        $self->assert_missing_delimitation();
    }
}
{

    package Liquid::Tag::If;
    use strict;
    use warnings;
    sub new { die 'New if tag!!!!!'; }
}

# back to main
#
my $snippet = <<'END';
{% if 1%}{% for x    in (1..10) %}one{{ 'string' }} {%endfor%}{% endif%}
END
pp(Liquid::Template->parse($snippet));
