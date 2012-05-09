use strict;
use warnings;

use 5.008000;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Math::GSLx::ODEIV2',
    dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
    license           => 'perl',
    requires          => {
      'perl'            => '5.008',
      parent            => 0,
      'PerlGSL::DiffEq' => 0.08,
    },
    configure_requires => {
      'Module::Build' => 0.38,
    },
);

$build->create_build_script;

