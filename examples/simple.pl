use lib '../lib';
use Solution;
#
use strict;
use warnings;
$|++;


my $template = Solution::Template->new();

$template->parse(<<'END');

{% if false %}
    A
{% elsif true %}
    B
{% else %}
    C
{% endif %}


{% unless true%}
    unless true
{%else%}
    else
{%endunless%}


--------------------------------------------------


{% for xyz in (1..10) %}{{ xyz }} {%endfor%}

{%comment%}This is a test.{%endcomment%}

{%capture ftw! %}
    {{ 'own' | replace:'o','p' }}
{%endcapture%}

{{ ftw! }}

END
#use Data::Dumper;
#warn Dumper $template;
warn $template->render({array => [qw[Just another Perl hacker]]}); __END__
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


































