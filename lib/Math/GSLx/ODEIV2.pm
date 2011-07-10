package Math::GSLx::ODEIV2;

use 5.008000;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

use parent 'Exporter';
our @EXPORT = ( qw/ ode_solver / );
our @EXPORT_OK = ( qw/ get_gsl_version / );

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
   #i.e.:        ( y'=v, v'=-y ) 
   my @derivs = (
     $y[1],
     -$y[0],
   );
   return @derivs;
 }
 
 $sine = ode_solver(\&eqn, [0, 2*3.14, 100]);

=head1 DESCRIPTION

This module provides a Perl-ish interface to the Gnu Scientific Library's (L<GSL|http://www.gnu.org/software/gsl/>) ODEIV2 library, (L<documentation|http://www.gnu.org/software/gsl/manual/html_node/Ordinary-Differential-Equations.html>). This library is the new ordinary differential equation solver as of GSL version 1.15. 

=head2 NAMESPACE

Why the C<Math::GSLx::> namespace? Well since Jonathon Leto has been kind enough to SWIG the entire GSL library into the C<Math::GSL::> namespace I didn't want to confuse things by impling that this module was in any way associated with that work. The C<x> namespaces have become popular so I ran with it.

=head2 INTERFACE STABILITY

This module is in an alpha state. It needs more tests and the ability to configure more of the options that the GSL library allows. While the author has put some thought into the interface it may change in the future as the above mentioned functionality is added or as bugs appear.

=head1 EXPORTED FUNCTIONS

=head2 ode_solver

This is the main function of the module. 

 $solution = C<ode_solver( $diffeq_code_ref, $t_range [, $opts_ref ])>.

=head3 arguments

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

The third argument is a hash reference containing other options. This is not yet used, but the author envisions this to set the error limits and the method used by the solver.

=head3 return

The return is an array reference of array references. Each element of the outer array reference will contain the time and function value of each function in order as above. This format allows easy loading into L<PDL> if so desired:

 $pdl = pdl($solution);

of course one may recover one column by simple use of a C<map>:

 @solution_t_vals  = map { $_->[0] } @$solution;
 @solution_y1_vals = map { $_->[1] } @$solution;
 ...

For a usage example see the L</SYNOPSIS> for a sine function given by C<y''(t)=-y(t)>.

=head1 NON-EXPORTED FUNCTIONS

=head2 get_gsl_version

A simple function taking no arguments and returning the version number of the GSL library as specified in C<gsl/gsl_version.h>. This was originally used for dependency checking but now remains simply for the interested user.

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
