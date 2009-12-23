package Solution::Tag;
{
    use strict;
    use warnings;
    our @ISA     = qw[Solution::Document];
    our $VERSION = 0.001;
    sub tag         { return $_[0]->{'tag_name'}; }
    sub end_tag     { return $_[0]->{'end_tag'} || undef; }
    sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }

    # Should be overridden by child classes
    sub new {
        return Solution::StandardError->new(
                                   'Please define a constructor in ' . $_[0]);
    }

    sub push_block {
        return Solution::StandardError->(
                'Please define a push_block method (for conditional tags) in '
                    . $_[0]);
    }
}
