use strict;
use warnings;

use Test::More;
use Data::Dumper;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 0;

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

{

  my $sin = ode_solver(\&eqn, [0, 2*3.14, 100]);

  is( ref $sin, "ARRAY", "ode_solver returns array ref" );

  is_deeply($sin->[0], [0,0,1], "Initial conditions are included in return"); 

  is( scalar @$sin, 101, "Returned the requested number of elements");

  my ($pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$sin;

  is( ref $pi_by_2, "ARRAY", "each solved element is an array ref");
  is( sprintf("%.5f", $pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1");

}

## Test step type option ##

foreach my $step_type (get_step_types()) {
  #skip steps which require Jacobian
  next if ($step_type =~ /_j$/);

  my $type_sin = ode_solver(\&eqn, [0, 2*3.14, 100], {type => $step_type});
  my ($type_pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$type_sin;
  is( sprintf("%.5f", $type_pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1 using {type => $step_type}");
}

## Test error type options ##

{

  my @error_tests = (
    { epsabs => 1e-4 },
    { epsabs => 0, epsrel => 1e-4 },
    { epsrel => 1e-4 },
    { epsabs => 1e-4, epsrel => 1e-4},
  );

  foreach my $error_test (@error_tests) {
    my $type_sin = ode_solver(\&eqn, [0, 2*3.14, 100], $error_test);
    my ($type_pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$type_sin;
    is( sprintf("%.5f", $type_pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1 using " . Dumper $error_test);
  }

}

done_testing();
