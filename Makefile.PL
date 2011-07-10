use 5.008000;
use ExtUtils::MakeMaker;

my $min_gsl_version = 1.15;

sub exit_early {
  my $message = shift || "";

  print "Math::GSLx::ODEIV2 requires GSL version >= $min_gsl_version" . $message . "\n";
  exit 0;
}

chomp(my $gsl_version = qx! gsl-config --version !);
exit_early() if ($!);

if ($gsl_version < $min_gsl_version) {
  exit_early(", but you only have $gsl_version");
} 

my $gsl_libs = qx! gsl-config --libs !;

WriteMakefile(
    NAME              => 'Math::GSLx::ODEIV2',
    VERSION_FROM      => 'lib/Math/GSLx/ODEIV2.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/GSLx/ODEIV2.pm', # retrieve abstract from module
       AUTHOR         => 'Joel <joel.a.berger@gmail.com>') : ()),
    LIBS              => [ $gsl_libs ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
