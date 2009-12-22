use lib '../lib';
use Liquid;
#
use strict;
use warnings;
$|++;



my $template = Liquid::Template->new();
$template->parse(<<'END');

{% if false %}
    A
{% elsif true %}
    B
{% else %}
    C
{% endif %}

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
Liquid                          | [done]                    |
    Liquid::Block               |                           |
    Liquid::Condition           | [done]                    |
    Liquid::Context             | [done]                    |
    Liquid::Document            | [done]                    |
    Liquid::Drop                |                           |
    Liquid::Errors              | [done]                    |
    Liquid::Extensions          |                           |
    Liquid::FileSystem          |                           |
    Liquid::HTMLTags            |                           |
    Liquid::Module_Ex           |                           |
    Liquid::StandardFilters     | [done]                    |
    Liquid::Strainer            |                           |
    Liquid::Tag                 |                           |
        Liquid::Tag::Assign     | [done]                    | Liquid::Tag
        Liquid::Tag::Capture    | [done] extended assign    | Liquid::Tag
        Liquid::Tag::Case       |                           |
        Liquid::Tag::Comment    | [done]                    | Liquid::Tag
        Liquid::Tag::Cycle      |                           |
        Liquid::Tag::For        | [done] for loop construct | Liquid::Tag
        Liquid::Tag::If         | [done] if/elsif/else      | Liquid::Tag
        Liquid::Tag::IfChanged  |                           |
        Liquid::Tag::Include    |                           |
        Liquid::Tag::Unless     |                           | Liquid::Tag::If
    Liquid::Template            |                           |
    Liquid::Variable            | [done] echo statement     | Liquid::Document
Liquid::Utility       *         | [temp] Non OO bin         |


































