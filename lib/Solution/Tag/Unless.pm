package Solution::Tag::Unless;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag::If];
    Solution->register_tag('unless') if $Solution::VERSION;

    sub render {
        my ($self) = @_;
        for my $block (@{$self->{'blocks'}}) {
            return $block->render()
                if !(grep { $_->is_true ? 1 : 0 } @{$block->{'conditions'}})
                    || ($block->{'tag_name'} eq 'else');
        }
    }
}
1;
