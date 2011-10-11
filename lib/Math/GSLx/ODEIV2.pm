package Math::GSLx::ODEIV2;

use 5.008000;
use strict;
use warnings;

use Math::GSLx::ODEIV2::ConfigData;

use Carp;
use Scalar::Util qw/looks_like_number/;

use parent 'Exporter';
our @EXPORT = ( qw/ ode_solver / );
our @EXPORT_OK = ( qw/ get_gsl_version get_step_types / );

our %EXPORT_TAGS;
push @{$EXPORT_TAGS{all}}, @EXPORT, @EXPORT_OK;

our $VERSION = '0.07';
$VERSION = eval $VERSION;

our $Verbose = 0;

require XSLoader;
XSLoader::load('Math::GSLx::ODEIV2', $VERSION);

my %step_types = (
  rk2   	=> 1,
  rk4   	=> 2,
  rkf45 	=> 3,
  rkck  	=> 4,
  rk8pd 	=> 5,
  rk1imp_j	=> 6,
  rk2imp_j	=> 7,
  rk4imp_j	=> 8,  
  bsimp_j 	=> 9,
  msadams	=> 10,
  msbdf_j	=> 11,
);

sub ode_solver {

  my ($eqn, $t_range, $opts) = @_;
  my $jac;
  if (ref $eqn eq 'ARRAY') {
    $jac = $eqn->[1] if defined $eqn->[1];
    $eqn = $eqn->[0];
  }
  croak "First argument must specify one or more code references" unless (ref $eqn eq 'CODE');

  ## Parse Options ##

  # Time range
  unless (ref $t_range eq 'ARRAY') {
    if (looks_like_number $t_range) {
      #if $t_range is a single number assume t starts at 0 and has 100 steps
      $t_range = [0, $t_range, 100];
    } else {
      croak "Could not understand 't range'";
    }
  } 

  # PDL
  my $have_pdl = Math::GSLx::ODEIV2::ConfigData->config('have_pdl');
  my $want_pdl = $opts->{PDL};
  if ($have_pdl) {
    if ($want_pdl) {
      carp "PDL return is not yet implemented";
    } else {
      #carp "Perl AoA unroll from PDL backend is not yet implemented";
    }
  } else {
    if ($want_pdl) {
      carp "Your installed version of Math::GSLx::ODEIV2 was compiled without PDL capability. To use the PDL backend please be sure that PDL is installed, then rebuild Math::GSLx::ODEIV2.";
    }
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

  # h step configuration
  my $h_init;
  my $h_max  = (exists $opts->{h_max} ) ? $opts->{h_max}  : 0;
  if (exists $opts->{h_init}) {
    $h_init = $opts->{h_init};

    # if the user specifies an h_init greater than h_max then croak
    if ($h_max && ($h_init > $h_max)) {
      croak "h_init cannot be set greater than h_max";
    }
  } else {
    $h_init = 1e-6;

    # if the default h_init would be greater tha h_max then set h_init = h_max
    if ($h_max && ($h_init > $h_max)) {
      $h_init = $h_max;
    }
  }

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
      $eqn, $jac, @$t_range, $step_type, $h_init, $h_max, $epsabs, $epsrel, $a_y, $a_dydt
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

Also, as of version 0.06, support for including a Jacobian of the system has been added, including the step types that this allows, however this functionality is almost totally untested. Until some of the stiff/extreme test cases can be ported from GSL the author is not certain the the functionality has been properly implemented. Sadly C<t/sine.*> pass even when not properly implemented, which is unnerving. I<Caveat emptor>.

=head1 EXPORTED FUNCTIONS

=head2 ode_solver

This is the main function of the module. 

 $solution = ode_solver( $diffeq_code_ref, $t_range)

or

 $solution = ode_solver( $diffeq_code_ref, $t_range, $opts_hashref)

or

 $solution = ode_solver( [$diffeq_code_ref, $jacobian_code_ref], $t_range, $opts_hashref)

Before detailing how to call C<ode_solver>, lets see how to construct the differential equation system.

=head3 the differential equation system

The differential equation system is defined in a code reference (in the example C<$diffeq_code_ref>). This code reference (or anonymous subroutine) must have a specific construction:

=over 

=item *

If called without arguments (i.e. C<< $diffeq_code_ref->() >>) it should return the initial conditions for the system, the number of initial values returned will set the number of differential equations. 

=item *

When called with arguments, the first argument will be time (or the independent parameter) and the rest will be the function values in the same order as the initial conditions. The returns in this case should be the values of the derivatives of the function values. 

If one or more of the returned values are not numbers (as determined by L<Scalar::Util> C<looks_like_number>), the solver will immediately return all calculations up until (and not including) this step, accompanied by a warning. This may be done intentionally to exit the solve routine earlier than the end time specified in the second argument.

=item *

Please note that as with other differential equation solvers, any higher order differential equations must be converted into systems of first order differential equations. 

=back

Optionally the system may be further described with a code reference which defines the Jacobian of the system (in the example C<$jacobian_code_ref>). Again, this code reference has a specific construction. The arguments will be passed in exactly the same way as for the equations code reference (though it will not be called without arguments). The returns should be two array references. 

=over

=item *

The first is the Jacobian matrix formed as an array reference containing array references. It should be square where each dimension is equal to the number of differential equations. Each "row" contains the derivatives of the related differential equations with respect to each dependant parameter, respectively.

 [
  [ d(dy[0]/dt)/d(y[0]), d(dy[0]/dt)/d(y[1]), ... ],
  [ d(dy[1]/dt)/d(y[0]), d(dy[1]/dt)/d(y[1]), ... ],
  ...
  [ ..., d(dy[n]/dt)/d(y[n])],
 ]

=item *

The second returned array reference contains the derivatives of the differential equations with respect to the independant parameter.

 [ d(dy[0]/dt)/dt, ..., d(dy[n]/dt)/dt ]

=back

The Jacobian code reference is only needed for certain step types, those step types whose names end in C<_j>.

=head3 required arguments

C<ode_solver> requires two arguments, they are as follows:

=head4 first argument

The first argument may be either a code reference or an array reference containing one or two code references. In the single code reference form this represents the differential equation system, constructed as described above. In the array reference form, the first argument must be the differential equation system code reference, but now optionally a code reference for the Jacobian of the system may be supplied as the second item.

=head4 second argument

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

C<type> specifies the step type to be used. The default is C<rk8pd>. The available step types can be found using the exportable function L</get_step_types>. Those step types whose name ends in C<_j> require the Jacobian.

=item *

C<h_init> the initial "h" step used by the solver. Defaults to C<1e-6>.

=item *

C<h_max> the maximum "h" step allowed to the adaptive step size solver. Set to zero to use the default value specified the GSL, this is the default behavior if unspecified. Note: the module will croak if C<h_init> is set greater than C<h_max>, however if C<h_init> is not specified and the default would violate this relation, C<h_init> will be set to C<h_max> implicitly.

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

Returns the available step types which may be specified in the L</ode_solver> function's options hashref. Note that those step types whose name end in C<_j> require the Jacobian.

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
