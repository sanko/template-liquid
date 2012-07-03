use strict;
use warnings;
use lib '../lib';
use lib 'lib';
use Liquid;
$|++;
Liquid->register_tag('dump', 'LiquidX::Tag::Dump');
print Liquid::Template->parse(
         <<'END')->render({array => [\%ENV, qw[this that the other], \@INC]});
   array: {% dump array %}
END
{

    package LiquidX::Tag::Dump;
    use strict;
    use warnings;
    use Carp qw[confess];
    BEGIN { our @ISA = qw[Liquid::Tag]; }

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
