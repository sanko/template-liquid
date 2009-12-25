package Solution::Template;
{
    use strict;
    use warnings;
    use lib '..';
    our $VERSION = 0.001;
    use Solution::Utility;
    sub context  { return $_[0]->{'context'} }
    sub filters  { return $_[0]->{'filters'} }
    sub tags     { return $_[0]->{'tags'} }
    sub document { return $_[0]->{'document'} }
    sub parent   { return $_[0]->{'parent'} }

    sub new {
        my ($class) = @_;
        my $self = bless {tags    => Solution->tags(),
                          filters => Solution->filters()
        }, $class;
        $self->{'context'} = Solution::Context->new({template => $self});
        return $self;
    }

    sub parse {
        my ($class, $source) = @_;
        my $self = ref $class ? $class : $class->new();
        my @tokens = Solution::Utility::tokenize($source);
        $self->{'document'}    # XXX - Unless a document is preexisting?
            = Solution::Document->new({template => $self});
        $self->{'document'}->parse(\@tokens);
        return $self;
    }

    sub render {
        my ($self, $args) = @_;
        return $self->context->stack(
            sub {
                $self->context->merge($args);
                return $self->document->render();
            }
        );
    }

    sub register_filter {
        my ($self, $name) = @_;     # warn 'Registering filter ' . $name;
        eval qq[require $name;];    # just in case
          #return @{$self->{'filters'}}{keys %${name}:: } = values %${name}::;
        return push @{$self->{'filters'}}, $name;
    }

    sub register_tag {
        my ($self, $tag_name, $package)
            = @_;                      # warn 'Registering filter ' . $name;
        eval qq[require $package;];    # just in case
        return $self->{'tags'}{$tag_name} = $package;
    }
}
1;
