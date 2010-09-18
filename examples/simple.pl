use lib '../lib';
use lib 'lib';
use Solution;

#
use strict;
use warnings;
$|++;
use Data::Dumper;

#die pp (Liquid->tags);
Solution->register_tag('dump', 'Solution::Tag::Custom::Dump');
my $template = Solution::Template->parse(<<'END');
{%for i in array%}
    Test. {{i}}
{%endfor%}
END
warn $template->render({condition => 1, array => [qw[one two three four]]});

#ddx$template->context->scope;
__END__
warn Solution::Template->parse(<<'INPUT')->render({hash => {key => 'value'}, list => [qw[key value]]});



{% if hash == list %}Yep.{% endif %}
INPUT


__END__

warn Solution::Template->parse(<<'END')->render();


{% assign grp_one = 'group 1' %}

{% cycle grp_one: 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}


END

exit;

use SolutionX::Tag::Large::Hadron::Collider;

warn Solution::Template->parse(q[{% lhc 2 %}Now, that's money well spent!{% endlhc %}])->render();
#warn Solution::Template->parse('{% random 88 %}')->render();



exit;


my $template = Solution::Template->new();
$template->register_tag('dump', 'Solution::Tag::Custom::Dump');
$template->parse('{% random 5 %}');
warn $template->render({array => [qw[Just another Perl hacker]]});

#warn pp $template;
{

    package Solution::Tag::Custom::Dump;
    use strict;
    use warnings;
    use Carp qw[confess];
    BEGIN { our @ISA = qw[Solution::Tag]; }

    sub new {
        my ($class, $args, $tokens) = @_;
        confess 'Missing template' if !defined $args->{'template'};
        $args->{'attrs'} ||= '.';
        my $self = bless {name     => 'dump-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          variable => $args->{'attrs'},
                          template => $args->{'template'},
                          parent   => $args->{'parent'},
        }, $class;
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $var = $$self{'variable'};
        $var
            = $var eq '.'  ? $self->template->context->scopes
            : $var eq '.*' ? [$self->template->context->scopes]
            :                $self->template->context->resolve($var);
        if (eval { require Data::Dump }) {
            return Data::Dump::pp($var);
        }
        else {
            require Data::Dumper;
            return Data::Dumper::Dumper($var);
        }
        return '';
    }
}
__END__
Module                            Purpose/Notes              Inheritance
-----------------------------------------------------------------------------------------------------------------------------------------
Solution                          | [done]                    |
    Solution::Block               |                           |
    Solution::Condition           | [done]                    |
    Solution::Context             | [done]                    |
    Solution::Document            | [done]                    |
    Solution::Drop                |                           |
    Solution::Errors              | [done]                    |
    Solution::Extensions          |                           |
    Solution::FileSystem          |                           |
    Solution::HTMLTags            |                           |
    Solution::Module_Ex           |                           |
    Solution::StandardFilters     | [done]                    |
    Solution::Strainer            |                           |
    Solution::Tag                 |                           |
        Solution::Tag::Assign     | [done]                    | Solution::Tag
        Solution::Tag::Capture    | [done] extended assign    | Solution::Tag
        Solution::Tag::Case       |                           |
        Solution::Tag::Comment    | [done]                    | Solution::Tag
        Solution::Tag::Cycle      |                           |
        Solution::Tag::For        | [done] for loop construct | Solution::Tag
        Solution::Tag::If         | [done] if/elsif/else      | Solution::Tag
        Solution::Tag::IfChanged  |                           |
        Solution::Tag::Include    |                           |
        Solution::Tag::Unless     | [done]                    | Solution::Tag::If
    Solution::Template            |                           |
    Solution::Variable            | [done] echo statement     | Solution::Document
Solution::Utility       *         | [temp] Non OO bin         |


































