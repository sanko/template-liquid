package Template::Liquid::Error;
{ $Template::Liquid::Error::VERSION = 'v1.0.0' }
sub message { return $_[0]->{'message'} }
sub fatal   { return $_[0]->{'fatal'} }

sub new {
    my ($class, $args, @etc) = @_;
    $args
        = {message => (@etc ? sprintf($args, @etc) : $args)
           || 'Unknown error'}
        if $args
        && !(ref $args && ref $args eq 'HASH');
    $args->{'fatal'} = defined $args->{'fatal'} ? $args->{'fatal'} : 0;
    require Carp;
    Carp::longmess() =~ m[^.+?\n\t(.+)]s;
    $args->{'message'} = sprintf '%s: %s %s', $class, $args->{'message'}, $1;
    return bless $args, $class;
}

sub raise {
    my ($s) = @_;
    $s = ref $s ? $s : $s->new($_[1]);
    die $s->message if $s->fatal;
    warn $s->message;
}
sub render { return sprintf '[%s] %s', ref $_[0], $_[0]->message; }

package Template::Liquid::ArgumentError;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::ContextError;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::FilterNotFound;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::FileSystemError;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::StandardError;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::SyntaxError;
our @ISA = qw'Template::Liquid::Error';

package Template::Liquid::StackLevelError;
our @ISA = qw'Template::Liquid::Error';
1;
