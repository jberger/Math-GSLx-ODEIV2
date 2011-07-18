use 5.008000;
use ExtUtils::MakeMaker;

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

WriteMakefile(
    NAME              => 'Math::GSLx::ODEIV2',
    VERSION_FROM      => 'lib/Math/GSLx/ODEIV2.pm',
    PREREQ_PM         => {
      parent => 0,
    },
    ABSTRACT_FROM     => 'lib/Math/GSLx/ODEIV2.pm',
    AUTHOR            => 'Joel Berger <joel.a.berger@gmail.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
      resources => {
        repository => {
          type => "git",
          url  => "git://github.com:jberger/Math-GSLx-ODEIV2.git",
          web  => "http://github.com/jberger/Math-GSLx-ODEIV2",
        },
      },
    },
    LIBS              => [ $gsl_libs ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

