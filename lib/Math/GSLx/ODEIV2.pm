package Math::GSLx::ODEIV2;

use 5.008000;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

use parent 'Exporter';
our @EXPORT = ( qw/ ode_solver / );
our @EXPORT_OK = ( qw/ get_gsl_version get_step_types / );

our %EXPORT_TAGS;
push @{$EXPORT_TAGS{all}}, @EXPORT, @EXPORT_OK;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

our $Verbose = 0;

require XSLoader;
XSLoader::load('Math::GSLx::ODEIV2', $VERSION);

my %step_types = (
  rk2   => 1,
  rk4   => 2,
  rkf45 => 3,
  rkck  => 4,
  rk8pd => 5,
);

sub ode_solver {

  my ($eqn, $t_range, $opts) = @_;
  croak "First argument must be a code reference" unless (ref $eqn eq 'CODE');

  ## Parse Options ##

  # Time range
  my @t_range;
  if (ref $t_range eq 'ARRAY') {
    @t_range = @$t_range;
  } elsif (looks_like_number $t_range) {
    #if $t_range is a single number assume t starts at 0 and has 100 steps
    @t_range = (0, $t_range, 100);
  } else {
    croak "Could not understand 't range'"; 
  }

  # Step type
  my $step_type = 0;
  if ( exists $opts->{type} and exists $step_types{ $opts->{type} } ) {
    $step_type = $step_types{ $opts->{type} };
  } 

  unless ($step_type) {
    carp "Using default step type 'rk8pd'\n" if $Verbose;
    $step_type = $step_types{rk8pd};
  }

  # Initial h_step
  my $h_step = (exists $opts->{h_step}) ? $opts->{h_step} : 1e-6;

  # Error levels
  my $epsabs = (exists $opts->{epsabs}) ? $opts->{epsabs} : 1e-6;
  my $epsrel = (exists $opts->{epsrel}) ? $opts->{epsrel} : 0.0;

  # Error types (set error scaling with logical name)
  my ($a_y, $a_dydt) = (1, 0);
  if (exists $opts->{scaling}) {
    if ($opts->{scaling} eq 'y') {
      # This is currently the default, do nothing
    } elsif ($opts->{scaling} eq 'yp') {
      ($a_y, $a_dydt) = (1, 0);
    } else {
      carp "Could not understand scaling specification. Using defaults.";
    }
  }

  # Individual error scalings (overrides logical name if set above)
  $a_y = $opts->{'a_y'} if (exists $opts->{'a_y'});
  $a_dydt = $opts->{'a_dydt'} if (exists $opts->{'a_dydt'});

  ## Run Solver ##

  # Run the solver at the C/XS level
  my $result;
  {
    local @_; #be sure the stack is clear before calling c_ode_solver!
    $result = c_ode_solver(
      $eqn, @t_range, $step_type, $h_step, $epsabs, $epsrel, $a_y, $a_dydt
    );
  }

  return $result;
}

sub get_step_types {
  return sort { $step_types{$a} <=> $step_types{$b} } keys %step_types;
}

1;

__END__
__POD__
=head1 NAME

Math::GSLx::ODEIV2 - Solve ODEs using Perl and GSL v1.15+

=head1 SYNOPSIS

 use Math::GSLx::ODEIV2;
 
 #Differential Equation(s)
 sub eqn {
 
   #initial conditions returned if called without parameters
   unless (@_) {
     return (0,1);
   }
 
   my ($t, @y) = @_;
   
   #example:   y''(t)==-y(t)
   my @derivs = (
     $y[1],	# y'[0] = y[1]
     -$y[0],	# y'[1] = - y[0]
   );
   return @derivs;
 }
 
 $sine = ode_solver(\&eqn, [0, 2*3.14, 100]);

=head1 DESCRIPTION

This module provides a Perl-ish interface to the Gnu Scientific Library's (L<GSL|http://www.gnu.org/software/gsl/>) ODEIV2 library, (L<documentation|http://www.gnu.org/software/gsl/manual/html_node/Ordinary-Differential-Equations.html>). This library is the new ordinary differential equation solver as of GSL version 1.15. 

=head2 NAMESPACE

Why the C<Math::GSLx::> namespace? Well since Jonathan Leto has been kind enough to SWIG the entire GSL library into the C<Math::GSL::> namespace I didn't want to confuse things by impling that this module was a part of that effort. The C<x> namespaces have become popular so I ran with it.

=head2 INTERFACE STABILITY

This module is in an alpha state. It needs more tests and the ability to configure more of the options that the GSL library allows. Currently this module leans on the fact that GSL has an extensive test suite. While the author has put some thought into the interface it may change in the future as the above mentioned functionality is added or as bugs appear. Bug reports are encouraged!

=head1 EXPORTED FUNCTIONS

=head2 ode_solver

This is the main function of the module. 

 $solution = ode_solver( $diffeq_code_ref, $t_range [, $opts_hashref ])

=head3 required arguments

The first argument, C<$diffeq_code_ref>, is a code reference to a subroutine (or anonymous sub) which specifies the differential equations. This subroutine must have a specific construction:

=over 

=item *

If called without arguments (i.e. C<< $diffeq_code_ref->() >>) it should return the initial conditions for the system, the number of initial values returned will set the number of differential equations. 

=item *

When called with arguments, the first argument will be time (or the independent parameter) and the rest will be the function values in the same order as the initial conditions. The returns in this case should be the values of the derivatives of the function values. 

=item *

Please note that as with other differential equation solvers, any higher order differential equations must be converted into systems of first order differential equations. 

=back

The second argument, C<$t_range>, specifies the time values that are used for the calculation. This may be used one of two ways:

=over

=item *

An array reference containing numbers specifying start time, finish time, and number of steps.

=item *

A scalar number specifying finish time. In this case the start time will be zero and 100 steps will be used.

=back

=head3 optional argument (the options hash reference)

The third argument, C<$opts_hashref>, is a hash reference containing other options. They are as follows:

=over

=item *

C<type> specifies the step type to be used. The default is C<rk8pd>. The available step types can be found using the exportable function L</get_step_types>. They are those steps defined by the C<gsl_odeiv2> library which do not need special extras, most commonly this means those that do not require the Jacobian of the system.

=item *

C<h_step> the initial "h" step used by the solver. Defaults to C<1e-6>.

=item * Error scaling options. These all refer to the adaptive step size contoller which is well documented in the L<GSL manual|http://www.gnu.org/software/gsl/manual/html_node/Adaptive-Step_002dsize-Control.html>. 

=over

=item *

C<epsabs> and C<epsrel> the allowable error levels (absolute and relative respectively) used in the system. Defaults are C<1e-6> and C<0.0> respectively.

=item *

C<a_y> and C<a_dydt> set the scaling factors for the function value and the function derivative respectively. While these may be used directly, these can be set using the shorthand ...

=item *

C<scaling>, a shorthand for setting the above option. The available values may be C<y> meaning C<{a_y = 1, a_dydt = 0}> (which is the default), or C<yp> meaning C<{a_y = 0, a_dydt = 1}>. Note that setting the above scaling factors will override the corresponding field in this shorthand.

=back

=back

=head3 return

The return is an array reference of array references. Each inner array reference will contain the time and function value of each function in order as above. This format allows easy loading into L<PDL> if so desired:

 $pdl = pdl($solution);

of course one may recover one column by simple use of a C<map>:

 @solution_t_vals  = map { $_->[0] } @$solution;
 @solution_y1_vals = map { $_->[1] } @$solution;
 ...

For a usage example see the L</SYNOPSIS> for a sine function given by C<y''(t)=-y(t)>.

=head1 EXPORTABLE FUNCTIONS

=head2 get_step_types

Returns the available step types which may be specified in the L</ode_solver> function's options hashref.

=head2 get_gsl_version

A simple function taking no arguments and returning the version number of the GSL library as specified in C<gsl/gsl_version.h>. This was originally used for dependency checking but now remains simply for the interested user.

=head1 FUTURE GOALS

On systems with PDL installed, I would like to include some mechanism which will store the numerical data in a piddle directly, saving the overhead of creating an SV for each of the pieces of data generated. I envision this happening as transparently as possible when PDL is available. This will probably take some experimentation to get it right.

=head1 SEE ALSO

=over

=item L<Math::ODE>

=item L<Math::GSL::ODEIV>

=item L<GSL|http://www.gnu.org/software/gsl/>

=item L<PDL>, L<website|http://pdl.perl.org> 

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Math-GSLx-ODEIV2>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
