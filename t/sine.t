use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Math::GSLx::ODEIV2') };

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

my $sin = ode_solver(\&eqn, [0, 2*3.14, 100]);

is( ref $sin, "ARRAY", "ode_solver returns array ref" );

my ($pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$sin;

is( ref $pi_by_2, "ARRAY", "each solved element is an array ref");
is( sprintf("%.5f", $pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1"); 

