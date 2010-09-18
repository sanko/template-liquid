package Solution::Template;
{
    use strict;
    use warnings;
    use lib '..';
    our $VERSION = 0.001;
    use Solution::Utility;

    #
    sub context  { $_[0]->{'context'} }
    sub filters  { $_[0]->{'filters'} }
    sub tags     { $_[0]->{'tags'} }
    sub document { $_[0]->{'document'} }
    sub parent   { $_[0]->{'parent'} }
    sub resolve  { $_[0]->{'context'}->resolve($_[1], $_[2]) }

    #
    sub new {
        my ($class) = @_;
        my $self = bless {tags    => Solution->tags(),      # Global list
                          filters => Solution->filters()    # Global list
        }, $class;
        return $self;
    }

    sub parse {
        my ($class, $source) = @_;
        my $self = ref $class ? $class : $class->new();
        my @tokens = Solution::Utility::tokenize($source);
        $self->{'document'} ||= Solution::Document->new({template => $self});
        $self->{'document'}->parse(\@tokens);
        return $self;
    }

    sub render {
        my ($self, $assigns, $info) = @_;
        $info ||= {};
        $info->{'template'} = $self;
        $self->{'context'} = Solution::Context->new($assigns, $info);
        return $self->document->render();
    }

    sub register_filter {
        my ($self, $name) = @_;
        eval qq[require $name;];
        return push @{$self->{'filters'}}, $name;
    }

    sub register_tag {
        my ($self, $tag_name, $package) = @_;
        eval qq[require $package;];
        return $self->{'tags'}{$tag_name} = $package;
    }
}
1;
