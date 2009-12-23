use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
my $solution = new_ok('Solution::Template');

# date
SKIP: {
    skip 'Cannot load DateTime module', 1 unless eval { require DateTime };
    is( $solution->parse('{{date|date:"%Y"}}')
            ->render({date => DateTime->from_epoch(epoch => 0)}),
        1970,
        '{{date|date:"%Y"}} => 1970 (DateTime)'
    );
}
SKIP: {
    skip 'Cannot load DateTimeX::Tiny module', 1
        unless eval {
        require DateTimeX::Tiny;
        require require DateTimeX::Lite::Strftime;
        };
    is( $solution->parse('{{date|date:"%Y"}}')
            ->render({date => DateTimeX::Tiny->from_epoch(epoch => 0)}),
        1970,
        '{{date|date:"%Y"}} => 2009 (DateTimeX::Tiny)'
    );
}
is($solution->parse('{{date|date:"%Y"}}')->render({date => gmtime(0)}),
    1970, '{{date|date:"%Y"}} => 1970 (int)');

# string/char case
is( $solution->parse(q[{{'this is a QUICK test.'|capitalize}}])->render(),
    'This is a quick test.',
    q[{{'this is a QUICK test.'|capitalize}} => This is a quick test.]
);
is( $solution->parse(q[{{'This is a QUICK test.'|downcase }}])->render(),
    'this is a quick test.',
    q[{{'This is a QUICK test.'|downcase }} => this is a quick test.]
);
is( $solution->parse(q[{{'This is a QUICK test.'|upcase }}])->render(),
    'THIS IS A QUICK TEST.',
    q[{{'This is a QUICK test.'|upcase }} => THIS IS A QUICK TEST.]
);

# array/lists
note('For these next few tests, C<array> is defined as C<[1 .. 6]>');
is($solution->parse(q[{{array | first}}])->render({array => [1 .. 6]}),
    '1', '{{array | first}} => 1');
is($solution->parse(q[{{array | last}}])->render({array => [1 .. 6]}),
    '6', '{{array | last }} => 6');
is($solution->parse(q[{{array | join}}])->render({array => [1 .. 6]}),
    '1 2 3 4 5 6', '{{array | join }} => 1 2 3 4 5 6');
is($solution->parse(q[{{array | join:", "}}])->render({array => [1 .. 6]}),
    '1, 2, 3, 4, 5, 6',
    '{{array | join:", " }} => 1, 2, 3, 4, 5, 6');
note('For this next test, C<array> is defined as C<[10,62,14,257,65,32]>');
is( $solution->parse(q[{{array | sort}}])
        ->render({array => [10, 62, 14, 257, 65, 32]}),
    '1014326265257',
    '{{array | sort}} => 1014326265257'
);
note(
    q[This next test works on strings (C<'This is a test'>)->render(), hashes (C<{Beatles=>'Apple',Nirvana=>'SubPop'}>)->render(), and arrays (C<[0..10]>)]
);
is($solution->parse(q[{{'This is a test' | size}}])->render(),
    '14', q[{{'This is a test' | size}} => 14]);
is($solution->parse(q[{{array | size}}])->render({array => [0 .. 10]}),
    '11', '{{array | size}} => 11');
is( $solution->parse(q[{{hash | size}}])
        ->render({hash => {Beatles => 'Apple', Nirvana => 'SubPop'}}),
    '2',
    q[{{hash | size}} => 2 (counts keys)]
);

# html/web (including the RubyLiquid bugs... ((sigh)))
is( $solution->parse(
           q[{{ '<div>Hello, <em id="whom">world!</em></div>' | strip_html}}])
        ->render(),
    'Hello, world!',
    q[{{'<div>Hello, <em id="whom">world!</em></div>'|strip_html}} => Hello, world!]
);
is( $solution->parse(
                 q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">' | strip_html}}'])
        ->render(),
    q[' B">'],
    q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">'|strip_html }}' => ' B">']
);
is( $solution->parse(q['{{ '<!-- <A comment> -->' | strip_html }}'])
        ->render(),
    q[' -->'],
    q['{{ '<!-- <A comment> -->'| strip_html }}' => ' -->']
);

# simple replacements
note(
    'The next few filters handle text where C<multiline> is defined as C<qq[This\n is\n a\n test.]>'
);
is( $solution->parse('{{multiline|strip_newlines}}')
        ->render({multiline => qq[This\n is\n a\n test.]}),
    'This is a test.',
    q[{{multiline|strip_newlines}} => 'This is a test.']
);
is( $solution->parse('{{multiline|newline_to_br}}')
        ->render({multiline => qq[This\n is\n a\n test.]}),
    qq[This<br />\n is<br />\n a<br />\n test.],
    qq[{{multiline|newline_to_br}} => This<br />\n is<br />\n a<br />\n test.]
);

# advanced replacements
is($solution->parse(q[{{'foofoo'|replace:'foo', 'bar'}}])->render(),
    'barbar', q[{{'foofoo'|replace:'foo', 'bar'}} => barbar]);
note(q[This next method uses C<this> which is defined as C<'that'>]);
is( $solution->parse(q[{{'Replace that with this'|replace:this,'this'}}])
        ->render({this => 'that'}),
    'Replace this with this',
    q[{{'Replace that with this|replace:this,'this'}} => Replace this with this]
);
is($solution->parse(q[{{'I have a listhp.'|replace:'th'}}])->render(),
    'I have a lisp.',
    q[{{'I have a listhp.'|replace:'th'}} => I have a lisp.]);
is( $solution->parse(q[{{ 'barbar' | replace_first:'bar','foo' }}])->render(),
    'foobar', q[{{ 'barbar' | replace_first:'bar','foo' }} => foobar]
);
is($solution->parse(q[{{ 'foobarfoobar' | remove:'foo' }}])->render(),
    'barbar', q[{{ 'foobarfoobar' | remove:'foo' }} => barbar]);
is($solution->parse(q[{{ 'barbar' | remove_first:'bar' }}])->render(),
    'bar', q[{{ 'barbar' | remove_first:'bar' }} => bar]);

# truncation
is( $solution->parse(q[{{ 'Running the halls!!!' | truncate:19 }}])->render(),
    'Running the hall...',
    q[{{ 'Running the halls!!!' | truncate:19 }} => Running the hall...]
);
note(q[This next method uses C<blah> which is defined as C<'STOP!'>]);
is( $solution->parse(q[{{ 'Any Colour You Like' | truncate:10,blah }}])
        ->render({blah => 'STOP!'}),
    'Any CSTOP!',
    q[{{ 'Any Colour You Like' | truncate:10,blah }} => Any CSTOP!]
);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);

=head2 C<truncate>

Truncate a string down to C<x> characters.

 {{ 'Why are you running away?' | truncate:4,'?' }} => Why?
 {{ 'Ha' | truncate:4 }} => Ha
 {{ 'Ha' | truncate:1,'Laugh' }} => Laugh
 {{ 'Ha' | truncate:1,'...' }} => ...

...and...

 {{ 'This is a long line of text to test the default values for truncate' | truncate }}

...becomes...

 This is a long line of text to test the default...

=head2 C<truncatewords>

Truncate a string down to C<x> words.

 {{ 'This is a very quick test of truncating a number of words' | truncatewords:5,'...' }}
 {{ 'This is a very quick test of truncating a number of words where the limit is fifteen' | truncatewords: }}

...becomes...

 This is a very quick...
 This is a very quick test of truncating a number of words where the limit...

=cut

# string concatenation
is($solution->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar', q[{{ 'bar' | prepend:'foo' }} => 'foobar']);
is($solution->parse(q[{{ 'foo' | append:'bar' }}])->render(),
    'foobar', q[{{ 'foo' | append:'bar' }} => 'foobar']);

# subtraction
is($solution->parse(q[{{ 4|minus:2 }}])->render, '2',
    q[{{ 4|minus:2 }} => 2]);
is($solution->parse(q[{{ 'Test'|minus:2 }}])->render,
    '', q[{{ 'Test'|minus:2 }} => ]);

# concatenation or simple addition
is($solution->parse(q[{{ 154| plus:1183 }}])->render(),
    '1337', q[{{ 154| plus:1183 }} => 1337]);
is($solution->parse(q[{{ 'W'| plus:'TF' }}])->render(),
    'WTF', q[{{ 'W'| plus:'TF' }} => WTF]);

# multiplication or string repetion
is($solution->parse(q[{{ 'foo'| times:4 }}])->render(),
    'foofoofoofoo', q[{{ 'foo'|times:4 }} => foofoofoofoo]);
is($solution->parse(q[{{ 5|times:4 }}])->render(),
    '20', q[{{ 5|times:4 }} => 20]);

# division
is($solution->parse(q[{{ 10 | divided_by:2 }}])->render(),
    '5', q[{{ 10 | divided_by:2 }} => 5]);

# I'm finished
done_testing();
