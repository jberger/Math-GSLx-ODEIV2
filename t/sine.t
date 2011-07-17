use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Math::GSLx::ODEIV2', ':all') };

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

## Test basic functionality ##

my $sin = ode_solver(\&eqn, [0, 2*3.14, 100]);

is( ref $sin, "ARRAY", "ode_solver returns array ref" );

is_deeply($sin->[0], [0,0,1], "Initial conditions are included in return"); 

my ($pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$sin;

is( ref $pi_by_2, "ARRAY", "each solved element is an array ref");
is( sprintf("%.5f", $pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1");

## Test step type option ##

my @step_types = get_step_types();
foreach my $step_type (@step_types) {
  my $type_sin = ode_solver(\&eqn, [0, 2*3.14, 100], {type => $step_type});
  my ($type_pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$type_sin;
  is( sprintf("%.5f", $type_pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1 using {type => $step_type}");
}

done_testing();
