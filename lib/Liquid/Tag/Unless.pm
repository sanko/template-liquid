package Liquid::Tag::Unless;
{
    use strict;
    use warnings;
    our $VERSION = 0.001;
    use lib '../../../lib';
    use Liquid::Error;
    use Liquid::Utility;
    our @ISA = qw[Liquid::Tag::If];
    Liquid->register_tag('unless') if $Liquid::VERSION;

    sub render {
        my ($self) = @_;
        for my $block (@{$self->{'blocks'}}) {
            return $block->render()
                if !$block->{'condition'} || ($block->{'tag_name'} eq 'else');
        }
    }
}
1;
