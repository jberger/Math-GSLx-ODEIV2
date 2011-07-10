package Math::GSLx::ODEIV2;

use 5.008000;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

use parent 'Exporter';
our @EXPORT = ( qw/ ode_solver get_gsl_version / );

our $VERSION = '0.01';
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Math::GSLx::ODEIV2', $VERSION);

sub ode_solver {

  my ($eqn, $t_range, $opts) = @_;
  croak "First argument must be a code reference" unless (ref $eqn eq 'CODE');

  my @t_range;
  if (ref $t_range eq 'ARRAY') {
    @t_range = @$t_range;
  } elsif (looks_like_number $t_range) {
    #if $t_range is a single number assume t starts at 0 and has 100 steps
    @t_range = (0, $t_range, 100);
  } else {
    croak "Could not understand 't range'"; 
  }

  my $result;

  {
    local @_; #be sure the stack is clear before calling c_ode_solver!
    $result = c_ode_solver($eqn, @t_range);
  }

  return $result;
}

1;

__END__
__POD__
=head1 NAME

Math::GSLx::ODEIV2 - Solve ODEs using GSL v1.15+

=head1 SYNOPSIS

 use Math::GSLx::ODEIV2;
 
 #Differential Equation(s)
 sub eqn {
 
   #initial conditions returned if called without parameters
   unless (@_) {
     return (0,1);
   }
 
   my ($t, @y) = @_;
   
   my @derivs = (
     $y[1],
     -$y[0],
   );
   return @derivs;
 }
 
 $sine = ode_solver(\&eqn, [0, 2*3.14, 100]);

=cut
