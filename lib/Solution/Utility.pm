package Solution::Utility;
{
    use strict;
    use warnings;
    our $FilterSeparator = qr[\s*\|\s*];
    my $ArgumentSeparator = qr[,];
    our $FilterArgumentSeparator    = qr[:];
    our $VariableAttributeSeparator = qr[\.];
    our $TagStart                   = qr[{%\s*];
    our $TagEnd                     = qr[\s*%}];
    our $VariableSignature          = qr[\(?[\w\-\.\[\]]\)?];
    my $VariableSegment = qr[[\w\-]\??]x;
    our $VariableStart = qr[{{\s*];
    our $VariableEnd   = qr[\s*}}];
    my $VariableIncompleteEnd = qr[}}?];
    my $QuotedString          = qr/"[^"]+"|'[^']+'/;
    my $QuotedFragment = qr/${QuotedString}|(?:[^\s,\|'"]|${QuotedString})+/;
    my $StrictQuotedFragment = qr/"[^"]+"|'[^']+'|[^\s,\|,\:,\,]+/;
    my $FirstFilterArgument
        = qr/${FilterArgumentSeparator}(?:${StrictQuotedFragment})/;
    my $OtherFilterArgument
        = qr/${ArgumentSeparator}(?:${StrictQuotedFragment})/;
    my $SpacelessFilter
        = qr/${FilterSeparator}(?:${StrictQuotedFragment})(?:${FirstFilterArgument}(?:${OtherFilterArgument})*)?/;
    our $Expression    = qr/(?:${QuotedFragment}(?:${SpacelessFilter})*)/;
    our $TagAttributes = qr[(\w+)(?:\s*\:\s*(${QuotedFragment}))?];
    my $AnyStartingTag = qr[\{\{|\{\%];
    my $PartialTemplateParser
        = qr[${TagStart}.*?${TagEnd}|${VariableStart}.*?${VariableIncompleteEnd}];
    my $TemplateParser = qr[(${PartialTemplateParser}|${AnyStartingTag})];
    our $VariableParser = qr[^
                            ${VariableStart}                        # {{
                                ([\w\.]+)    #   name
                                (?:\s*\|\s*(.+)\s*)?                 #   filters
                            ${VariableEnd}                          # }}
                            $]x;
    our $VariableFilterArgumentParser
        = qr[\s*,\s*(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))];

    sub tokenize {
        map { $_ ? $_ : () } split $TemplateParser, shift || '';
    }
}
