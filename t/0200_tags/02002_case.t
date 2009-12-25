use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
my $solution = new_ok('Solution::Template');

#
is( $solution->parse(
          '{%case condition%}{%when 1%}One{%else%}Else{%endcase%}')->render(),
    'Else',
    'Falls back to else'
);
is( $solution->parse('{%case condition%}{%when 1%}One{%endcase%}')->render(),
    '', 'Does nothing when nothing matches and no else fallback [B]'
);
is( $solution->parse(
        '{%case condition%}{%when 1%}One{%when 2 or 3%}Two or Three{%endcase%}'
        )->render({condition => 12}),
    '',
    'Does nothing when nothing matches and no else fallback [B]'
);
is( $solution->parse('{%case condition%}{%when 1%}One{%endcase%}')
        ->render({condition => 1}),
    'One',
    'Simple condition [A]'
);
is( $solution->parse(
                  '{%case condition%}{%when 1%}One{%when 3%}Three{%endcase%}')
        ->render({condition => 3}),
    'Three',
    'Simple condition [B]'
);
is( $solution->parse(
        '{%case condition%}{%when 1%}One{%when 2 or 3%}Two or Three{%endcase%}'
        )->render({condition => 2}),
    'Two or Three',
    'Compound condition [C]'
);
is( $solution->parse(
        '{%case condition%}    {%when 1%}One{%when 2 or 3%}Two or Three{%endcase%}'
        )->render({condition => 100}),
    '',
    'Compound condition [D]'
);
is( $solution->parse(
        '{%case condition%}{%when "Alpha"%}A{%when "Beta" or "Gamma"%}B or C{%endcase%}'
        )->render({condition => 'Alpha'}),
    'A',
    'Non-numeric condition [A]'
);
is( $solution->parse(
        '{%case "Gamma"%}{%when "Alpha"%}A{%when "Beta"%}B{%when "Gamma"%}C{%endcase%}'
        )->render(),
    'C',
    'Non-numeric condition [B]'
);

# I'm finished
done_testing();
