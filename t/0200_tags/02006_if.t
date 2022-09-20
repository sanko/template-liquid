use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;

# Various condition types
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', '1 == 1');
{% if 1 == 1 %}One equals one{% endif %}
INPUT
One equals one
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', '1.1 == 1.1');
{% if 1.1 == 1.1 %}1.1 equals 1.1{% endif %}
INPUT
1.1 equals 1.1
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', '1 != 1');
{% if 1 != 1 %}One does not equal one{% endif %}
INPUT

EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', '1.1 != 1.1');
{% if 1.1 != 1.1 %}1.1 does not equal 1.1{% endif %}
INPUT

EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', q[1 < 2]);
{% if 1 < 2 %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', q[1.1 < 2.2]);
{% if 1.1 < 2.2 %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', q[2.2 > 1.1]);
{% if 2.2 > 1.1 %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', q[1 > 2]);
{% if 1 > 2 %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' contains 'string']);
{% if 'This string' contains 'string' %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' contains 'some other string']);
{% if 'This string' contains 'some other string' %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' == 'This string']);
{% if 'This string' == 'This string' %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' == 'some other string']);
{% if 'This string' == 'some other string' %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' != 'some other string']);
{% if 'This string' != 'some other string' %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' != 'This string']);
{% if 'This string' != 'This string' %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(list => [qw[some other value]]), <<'EXPECTED', q[list contains 'other']);
{% if list contains 'other' %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(list => [qw[some other value]]), <<'EXPECTED', q[list contains 'missing element']);
{% if list contains 'missing element' %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(list_one => [qw[a b c d]], list_two => [qw[a b c d]]), <<'EXPECTED', q[list_one == list_two [A]]);
{% if list_one == list_two %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(list_one => [qw[a b c d]], list_two => [qw[a b c d e]]), <<'EXPECTED', q[list_one == list_two [B]]);
{% if list_one == list_two %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(list_one => [qw[a b c d]], list_two => [qw[a b c e]]), <<'EXPECTED', q[list_one == list_two [C]]);
{% if list_one == list_two %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash_one => {key => 'value'}, hash_two => {key => 'value'}), <<'EXPECTED', q[hash_one == hash_two [A]]);
{% if hash_one == hash_two %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash_one => {key => 'value'}, hash_two => {key => 'wrong value'}), <<'EXPECTED', q[hash_one == hash_two [B]]);
{% if hash_one == hash_two %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash_one => {key => 'value'}, hash_two => {other_key => 'value'}), <<'EXPECTED', q[hash_one == hash_two [C]]);
{% if hash_one == hash_two %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash => {key => 'value'}, list => [qw[key value]]), <<'EXPECTED', q[hash == list]);
{% if hash == list %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash => {key => 'value'}), <<'EXPECTED', q[hash contains 'key']);
{% if hash contains 'key' %}Yep.{% endif %}
INPUT
Yep.
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(hash => {key => 'value'}), <<'EXPECTED', q[hash contains 'missing key']);
{% if hash contains 'missing key' %}Yep.{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
                         <<'INPUT')->render(), <<'EXPECTED', 'else fallback');
{% if 1 != 1 %}One does not equal one{% else %}else{% endif %}
INPUT
else
EXPECTED
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', '5 = 5');
{% if 1 != 1 %}One does not equal one{% elsif 5 == 5 %}Five equals five{% endif %}
INPUT
Five equals five
EXPECTED
is( Template::Liquid->parse(
                      <<'INPUT')->render(), <<'EXPECTED', 'no fallback else');
{% if 1 != 1 %}One does not equal one{% elsif 5 == 50 %}Five equals fifty{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound if [A] (1 != 1 or 1 < 5)');
{% if 1 != 1 or 1 < 5 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 %}
    Five equals fifty
{% endif %}
INPUT

    One does not equal one or one is less than five.

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound if [B] (1 != 1 and 1 < 5)');
{% if 1 != 1 and 1 < 5 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 %}
    Five equals fifty
{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [A] (elsif 5 == 50 or 3 > 1)');
{% if 0 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 or 3 > 1 %}
    Five equals fifty
{% endif %}
INPUT

    Five equals fifty

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [B] (elsif 5 == 50 and 3 > 1)');
{% if 0 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 and 3 > 1 %}
    Five equals fifty
{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [A] (elseif 5 == 50 or 3 > 1)');
{% if 0 %}
    One does not equal one or one is less than five.
{% elseif 5 == 50 or 3 > 1 %}
    Five equals fifty
{% endif %}
INPUT

    Five equals fifty

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound elsif [B] (else?if 5 == 50 and 3 > 1)');
{% if 0 %}
    One does not equal one or one is less than five.
{% elseif 5 == 50 and 3 > 1 %}
    Five equals fifty
{% endif %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'condition with and/or in quotes if [A] (myvar == "foo and bar")');
{% assign myvar = "foo and bar" %}{% if myvar == "foo and bar" %}
    foo and bar
{% else %}
    Not foo and bar
{% endif %}
INPUT

    foo and bar

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound condition with "and" in quotes if [A] (myvar == "foo and bar" and 5 > 1)');
{% assign myvar = "foo and bar" %}{% if myvar == "foo and bar" and 5 > 1 %}
    foo and bar
{% else %}
    Not foo and bar
{% endif %}
INPUT

    foo and bar

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound condition with "and" in quotes if [A] (myvar == "foo and bar" and 5 < 1)');
{% assign myvar = "foo and bar" %}{% if myvar == "foo and bar" and 5 < 1 %}
    foo and bar
{% else %}
    Not foo and bar
{% endif %}
INPUT

    Not foo and bar

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound condition with "or" in quotes if [A] (myvar == "foo or bar" and 5 > 1)');
{% assign myvar = "foo or bar" %}{% if myvar == "foo or bar" and 5 > 1 %}
    foo or bar
{% else %}
    Not foo or bar
{% endif %}
INPUT

    foo or bar

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound condition with "or" in quotes if [A] (myvar == "foo or bar" and 5 < 1)');
{% assign myvar = "foo or bar" %}{% if myvar == "foo or bar" and 5 < 1 %}
    foo or bar
{% else %}
    Not foo or bar
{% endif %}
INPUT

    Not foo or bar

EXPECTED

# I'm finished
done_testing();
