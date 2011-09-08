use strict;
use warnings;

use Test::More;

BEGIN{ use_ok('Math::GSLx::ODEIV2'); }

my $eqn_oregonator = sub {

  unless (@_) {
    return (1, 2, 3);
  }

  my ($t, @y) = @_;

  my $c1 = 77.27;
  my $c2 = 8.375e-6;
  my $c3 = 0.161;

  my @f;

  $f[0] = $c1 * ($y[1] + $y[0] * (1 - $c2 * $y[0] - $y[1]));
  $f[1] = 1 / $c1 * ($y[2] - $y[1] * (1 + $y[0]));
  $f[2] = $c3 * ($y[0] - $y[2]);

  return @f;

};

my $jac_oregonator = sub {

  my ($t, @y) = @_;

  my $c1 = 77.27;
  my $c2 = 8.375e-6;
  my $c3 = 0.161;

  my @dfdy;
  my @dfdt;

  $dfdy[0] = $c1 * (1 - 2 * $c2 * $y[0] - $y[1]);
  $dfdy[1] = $c1 * (1 - $y[0]);
  $dfdy[2] = 0.0;

  $dfdy[3] = 1 / $c1 * (-$y[1]);
  $dfdy[4] = 1 / $c1 * (-1 - $y[0]);
  $dfdy[5] = 1 / $c1;

  $dfdy[6] = $c3;
  $dfdy[7] = 0.0;
  $dfdy[8] = -$c3;

  $dfdt[0] = 0.0;
  $dfdt[1] = 0.0;
  $dfdt[2] = 0.0;

  return (\@dfdy, \@dfdt);

};

my $res_oregonator = ode_solver([$eqn_oregonator, $jac_oregonator], [0, 360, 100], {});
