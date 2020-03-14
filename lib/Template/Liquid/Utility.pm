package Template::Liquid::Utility;
use experimental 'signatures';
use strict;
use warnings;
our $VERSION         = '1.0.18';
our $FilterSeparator = qr[\s*\|\s*]o;
my $ArgumentSeparator = qr[,]o;
our $FilterArgumentSeparator    = qr[\s*:\s*]o;
our $VariableAttributeSeparator = qr[\.]o;
our $TagStart                   = qr[(?:\s*{%-\s*|{%\s*)]o;
our $TagEnd                     = qr[(?:\s*-%}\s*|\s*%})]o;
our $VariableSignature          = qr{\(?[\w\-\.\[\]]\)?}o;
my $VariableSegment = qr[[\w\-]\??]ox;
our $VariableStart = qr[(?:\s*\{\{-\s*|\{\{-?\s*)]o;
our $VariableEnd   = qr[(?:\s*-?}}\s*?|\s*}})]o;
my $VariableIncompleteEnd = qr[(?:\s*-}}?\s*|}})];
my $QuotedString          = qr/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/o;
my $QuotedFragment = qr/${QuotedString}|(?:[^\s,\|'"]|${QuotedString})+/o;
my $StrictQuotedFragment = qr/"[^"]+"|'[^']+'|[^\s,\|,\:,\,]+/o;
my $FirstFilterArgument
    = qr/${FilterArgumentSeparator}(?:${StrictQuotedFragment})/o;
my $OtherFilterArgument
    = qr/${ArgumentSeparator}(?:${StrictQuotedFragment})/o;
my $SpacelessFilter
    = qr/${FilterSeparator}(?:${StrictQuotedFragment})(?:${FirstFilterArgument}(?:${OtherFilterArgument})*)?/o;
our $Expression    = qr/(?:${QuotedFragment}(?:${SpacelessFilter})*)/o;
our $TagAttributes = qr[(\w+)(?:\s*\:\s*(${QuotedFragment}))?]o;
my $AnyStartingTag = qr[\{\{|\{\%]o;
my $PartialTemplateParser
    = qr[${TagStart}.+?${TagEnd}|${VariableStart}.+?${VariableIncompleteEnd}]os;
my $TemplateParser = qr[(${PartialTemplateParser}|${AnyStartingTag})]os;
our $VariableParser
    = qr[${VariableStart}([\w\.]+)(?:\s*\|\s*(.+)\s*)?${VariableEnd}$]so;
our $VariableFilterArgumentParser = qr[
 (?:
	(?:\s*,\s*)?
	(?:
	   ((?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\"))
	  |((?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\'))
	  |(?:([^,]+)(?:\s*,\s*)?)
	)
)]smx;
our $TagMatch = qr[^${Template::Liquid::Utility::TagStart}   # {%
                                (.+?)                              # etc
                              ${Template::Liquid::Utility::TagEnd} # %}
                             $]sox;
our $VarMatch = qr[^${Template::Liquid::Utility::VariableStart} # {{
                        (.+?)                           #  stuff + filters?
                    ${Template::Liquid::Utility::VariableEnd}   # }}
                $]sox;

sub tokenizeX {
    map { $_ ? $_ : () } split $TemplateParser, shift || '';
}




my $T_TAG_OPEN = qr[(?:\{%|\s*\{%-)\s*]o;
my $T_VAR_OPEN = qr[(?:\{\{|\s*\{\{-)\s*]o;
my $T_SIN_QUOT = "'";
my $T_DOU_QUOT = '"';
my $T_TAG_CLOS = qr[\s*(?:%}|-%}\s*)]o;
my $T_VAR_CLOS = qr[\s*(?:}}|-}}\s*)]o;
my $T_VAR_CLO2 = qr[}]o;
#
my $S_NIL     = 0;
my $S_TAG     = 1;
my $S_VAR     = 2;
my $S_TAG_SIN = 3;
my $S_TAG_DOU = 4;
my $S_VAR_SIN = 5;
my $S_VAR_DOU = 6;
#
my $T_PARSER
    = qr/($T_TAG_OPEN|$T_VAR_OPEN|$T_DOU_QUOT|$T_SIN_QUOT|$T_VAR_CLOS|$T_TAG_CLOS|$T_VAR_CLO2)/om;

sub tokenize($source) {
    my @output;
    my $s       = $S_NIL;
    my $current = "";
    for my $t ( split $T_PARSER, $source ) {
        if ( $t =~ /^$T_TAG_OPEN$/ && $s <= $S_VAR ) {
            $s = $S_TAG;
            push @output, $current;
            $current = $t;
        }
        elsif ( $t =~ /^$T_VAR_OPEN$/ && $s <= $S_VAR ) {
            $s = $S_VAR;
            push @output, $current;
            $current = $t;
        }
        elsif ( $t eq $T_SIN_QUOT && $s == $S_TAG ) {
            $s = $S_TAG_SIN;
            $current .= $t;
        }
        elsif ( $t eq $T_SIN_QUOT && $s == $S_TAG_SIN ) {
            $s = $S_TAG;
            $current .= $t;
        }
        elsif ( $t eq $T_DOU_QUOT && $s == $S_TAG ) {
            $s = $S_TAG_DOU;
            $current .= $t;
        }
        elsif ( $t eq $T_DOU_QUOT && $s == $S_TAG_DOU ) {
            $s = $S_TAG;
            $current .= $t;
        }
        elsif ( $t eq $T_SIN_QUOT && $s == $S_VAR ) {
            $s = $S_VAR_SIN;
            $current .= $t;
        }
        elsif ( $t eq $T_SIN_QUOT && $s == $S_VAR_SIN ) {
            $s = $S_VAR;
            $current .= $t;
        }
        elsif ( $t eq $T_DOU_QUOT && $s == $S_VAR ) {
            $s = $S_VAR_DOU;
            $current .= $t;
        }
        elsif ( $t eq $T_DOU_QUOT && $s == $S_VAR_DOU ) {
            $s = $S_VAR;
            $current .= $t;
        }
        elsif ( $t =~ /^$T_TAG_CLOS$/ && $s == $S_TAG ) {
            $s = $S_NIL;
            $current .= $t;
            push @output, $current;
            $current = "";
        }
        elsif ( $t =~ /^(?:$T_VAR_CLOS|$T_VAR_CLO2)$/ && $s == $S_VAR ) {
            $s = $S_NIL;
            $current .= $t;
            push @output, $current;
            $current = "";
        }
        else {
            $current .= $t;
        }
    }
    push @output, $current unless $current eq '';
    grep { length $_ } @output;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Utility - Utility stuff. Watch your step.

=head1 Description

It's best to just forget this package exists. It's messy but seems to work.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Create your own filters">'s docs on custom
filter creation

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
