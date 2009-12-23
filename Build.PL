
=pod

=for license Artistic License 2.0 | Copyright (C) 2009 by Sanko Robinson

=for author Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=for abstract Module::Build based install

=cut

use strict;
use warnings;
use Module::Build;
use lib 'inc';
use File::Find qw[find];
my $automated_testing = $ENV{AUTOMATED_TESTING} || $ENV{PERL_MM_USE_DEFAULT};
my $is_developer = ($ENV{RELEASE_TESTING} || -d '.git');
my @tests;
find \&find_cb, qw[t/0100_filters], ($is_developer ? 't/9000_author' : ());
@tests = sort @tests;
my $class = $is_developer ? 'MBX::Solution::Developer' : 'MBX::Solution';
$class = 'Module::Build';    # XXX

if (!eval "require $class") {
    printf 'Failed to load %s: %s This ain\'t good, so... bye!', $class, $@;
    exit 0;
}
my $mb = $class->new(
    module_name       => 'Solution',
    license           => 'artistic_2',
    dist_author       => 'Sanko Robinson <sanko@cpan.org>',
    dist_version_from => 'lib/Solution.pm',
    dist_abstract     => 'Simple, Stateless Template System',
    requires          => {
                 'File::Find'    => 0,
                 'Module::Build' => '0.36',
                 perl            => 5.006001,
                 'Test::More'    => '0.94'
    },
    build_requires => {'File::Find'    => 0,
                       'Module::Build' => '0.36',
                       perl            => 5.006001,
                       'Test::More'    => '0.94'
    },
    add_to_cleanup => [qw[Liquid-*]],
    no_index       => {directory => [qw[examples inc t]]},
    test_files     => \@tests,
    meta_merge     => {
        generated_by => 'Conversion, software version 7.0',
        keywords     => [qw[Liquid Template Engine]],
        resources    => {

            #bugtracker => 'http://github.com/sanko/fltk-perl/issues',
            #ChangeLog => 'http://github.com/sanko/fltk-perl/commits/master',
            #homepage  => 'http://sanko.github.com/fltk-perl/',
            #license => 'http://www.perlfoundation.org/artistic_license_2_0',
            #repository => 'http://github.com/sanko/fltk-perl'
        }
    },
    get_options => {'interactive!' => {},
                    'messy!'       => {}
    }
);
$mb->notes(automated_testing => $automated_testing       ? 1 : 0);
$mb->notes(is_developer      => $is_developer            ? 1 : 0);
$mb->notes(verbose           => $mb->args('messy')       ? 1 : 0);
$mb->notes(interactive       => $mb->args('interactive') ? 1 : 0);
$mb->notes(test_suite        => \@tests);
$mb->notes(gmtime            => scalar gmtime);
$mb->create_build_script;
exit 0;

sub find_cb {
    return if -d $_ or -l $_;
    return unless -T $_;
    return unless $_ =~ m[.+\.t$];
    return push @tests, $File::Find::name;
}
