use strict;
use warnings;

use 5.008000;
use Module::Build;

my $min_gsl_version = 1.15;

sub exit_early {
  my $message = shift || "";

  print "Math::GSLx::ODEIV2 requires GSL version >= $min_gsl_version" . $message . "\n";
  exit 0;
}

my $gsl_version = qx/ gsl-config --version /;
exit_early("\n [gsl-config --version: $!]") if ($?);

chomp($gsl_version);

if ($gsl_version < $min_gsl_version) {
  exit_early(", but you only have $gsl_version");
} 

my $gsl_libs = qx! gsl-config --libs !;

my $have_pdl = Module::Build->check_installed_status('PDL')->{ok};
my $extra_compiler_flags .=
  '-Iinc' . ( $have_pdl ? ' -DMATH_GSLX_ODEIV2_USE_PDL' : '' );

my $build = Module::Build->new(
    module_name       => 'Math::GSLx::ODEIV2',
    dist_version_from => 'lib/Math/GSLx/ODEIV2.pm',
    dist_abstract     => 'Solve ODEs using Perl and GSL v1.15+',
    dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
    license           => 'perl',
    requires          => {
      'perl' => '5.008',
      parent => 0,
    },
    configure_requires => {
      'Module::Build' => 0.38,
    },
    build_requires    => {
      'ExtUtils::CBuilder' => 0,
    },
    c_source => 'src',
    extra_compiler_flags => $extra_compiler_flags,
    extra_linker_flags => $gsl_libs,
    #meta_merge        => {
    #  resources => {
    #    repository => {
    #      type => "git",
    #      url  => "git://github.com/jberger/Math-GSLx-ODEIV2.git",
    #      web  => "http://github.com/jberger/Math-GSLx-ODEIV2",
    #    },
    #  },
    #},
);

$build->config_data('have_pdl', $have_pdl);

$build->create_build_script;

