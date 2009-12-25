use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
my $solution = new_ok('Solution::Template');

# integer range
is($solution->parse('{%for x in (1..5) %}X{%endfor%}')->render(),
    'XXXXX', '(1..5) => XXXXX');

# integer ranges with values which must be resolved
note(
    'For this next bit, render is given: { range => { from => 10, to => 29 } }'
);
is( $solution->parse('{%for x in (range.from..range.to) %}X{%endfor%}')
        ->render({range => {from => 10, to => 29}}),
    'X' x 20,
    '(range.from..range.to) => q[X] x 20'
);
note('Checking the various forloop-local values...');

# simple variable
is($solution->parse('{%for x in (100..105) %}{{x}} {%endfor%}')->render(),
    '100 101 102 103 104 105 ',
    '(100..105) => 100 101 102 103 104 105 ');

# deep variable (This is a Liquid bug. The syntax is valid but it doesn't work)
is( $solution->parse('{%for x.y in (100..105) %}{{x.y}} {%endfor%}')
        ->render(),
    '100 101 102 103 104 105 ',
    'x.y => 100 101 102 103 104 105 '
);
is( $solution->parse(
        '{%for x in (100..105)%}{{x}}{%unless forloop.last%}, {%endunless%}{%endfor%}'
        )->render(),
    '100, 101, 102, 103, 104, 105',
    'forloop.last [A] => 100, 101, 102, 103, 104, 105'
);

# check limit:int
is( $solution->parse('{%for x in (100..105) limit:2%}{{x}} {%endfor%}')
        ->render(),
    '100 101 ',
    'limit:2 => 100 101 '
);
is( $solution->parse('{%for x in (100..105) limit:0%}{{x}} {%endfor%}')
        ->render(),
    '', 'limit:0 => '
);
is( $solution->parse(
        '|{%assign limit = 5 %}{%for x in (100..105) limit:limit%}{{x}} {%endfor%}|'
        )->render(),
    '|100 101 102 103 104 |',
    'limit:limit => |100 101 102 103 104 | (where limit is defined as 5)'
);
is( $solution->parse(
        '|{%assign limit = 50 %}{%for x in (100..105) limit:limit%}{{x}} {%endfor%}|'
        )->render(),
    '|100 101 102 103 104 105 |',
    'limit:limit => |100 101 102 103 104 105 | (where limit is defined as 50)'
);
is( $solution->parse('|{%for x in (100..105) limit:%}{{x}} {%endfor%}|')
        ->render(),
    '|100 101 102 103 104 105 |',
    'limit: => |100 101 102 103 104 105 |'
);

# check offset:int
is( $solution->parse('{%for x in (100..105) offset:2%}{{x}} {%endfor%}')
        ->render(),
    '102 103 104 105 ',
    'offset:2 => 102 103 104 105 '
);
is( $solution->parse('{%for x in (100..105) offset:0%}{{x}} {%endfor%}')
        ->render(),
    '100 101 102 103 104 105 ',
    'offset:0 => 100 101 102 103 104 105 '
);
is( $solution->parse(
        '|{%assign offset = 5 %}{%for x in (100..105) offset:offset%}{{x}} {%endfor%}|'
        )->render(),
    '|105 |',
    'offset:offset => |105 | (where offset is defined as 5)'
);
is( $solution->parse(
        '|{%assign offset = 50 %}{%for x in (100..105) offset:offset%}{{x}} {%endfor%}|'
        )->render(),
    '||',
    'offset:offset => || (where offset is defined as 50)'
);
is( $solution->parse('|{%for x in (100..105) offset:%}{{x}} {%endfor%}|')
        ->render(),
    '|100 101 102 103 104 105 |',
    'offset: => |100 101 102 103 104 105 |'
);
is( $solution->parse(
                '|{%for x in (100..105) offset:2 limit:2 %}{{x}} {%endfor%}|')
        ->render(),
    '|102 103 |',
    'offset:2 limit:2 => |102 103 |'
);
is( $solution->parse(
              '|{%for x in (100..105) offset:200 limit:2 %}{{x}} {%endfor%}|')
        ->render(),
    '||',
    'offset:200 limit:2 => ||'
);
is( $solution->parse(
                '|{%for x in (100..105) offset:2 limit:0 %}{{x}} {%endfor%}|')
        ->render(),
    '||',
    'offset:2 limit:0 => ||'
);

# check reversed
is( $solution->parse('|{%for x in (100..105) reversed %}{{x}} {%endfor%}|')
        ->render(),
    '|100 101 102 103 104 105 |',
    'reversed => |100 101 102 103 104 105 |'
);

# check reversed with offset and limit
is( $solution->parse(
               '|{%for x in (100..105) reversed offset:2 %}{{x}} {%endfor%}|')
        ->render(),
    '|105 104 103 102 |',
    'reversed offset:2 => |105 104 103 102 |'
);
is( $solution->parse(
               '|{%for x in (100..105) reversed limit:2  %}{{x}} {%endfor%}|')
        ->render(),
    '|101 100 |',
    'reversed limit:2 => |101 100 |'
);
is( $solution->parse(
        '|{%for x in (100..105) reversed offset:2 limit:2  %}{{x}} {%endfor%}|'
        )->render(),
    '|103 102 |',
    'reversed offset:2 limit:2 => |103 102 |'
);

# check reversed with array
# check all the forloop vars
# make sure the local variable overrides the higher scope
# I'm finished
done_testing();
