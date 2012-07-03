use strict;
use warnings;
use lib '../lib';
use lib 'lib';
use Liquid;
$|++;
my $template = Liquid::Template->parse(<<'END');
{%for i in array%}
    Test. {{i}}
{%endfor%}
END
warn $template->render({condition => 1, array => [qw[one two three four]]});
print Liquid::Template->parse(
      <<'INPUT')->render({hash => {key => 'value'}, list => [qw[key value]]});
{% if hash == list %}Yep.{% endif %}
INPUT
warn Liquid::Template->parse(<<'END')->render();
{% assign grp_one = 'group 1' %}

{% cycle grp_one: 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
END
