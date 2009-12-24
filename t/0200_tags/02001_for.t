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

# check all the forloop vars

# make sure the local variable overrides the higher scope

# check limit:int

# check offset:int

# check reversed

# check reversed with array

# I'm finished
done_testing();
