use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

# Make sure Solution.pm works (tests taken from t/2000_tags/02006_if.t)
is(Solution->parse(<<'INPUT')->render(), <<'EXPECTED', '1 == 1');
{% if 1 == 1 %}One equals one{% endif %}
INPUT
One equals one
EXPECTED

# I'm finished
done_testing();
