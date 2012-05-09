package Math::GSLx::ODEIV2;

use 5.008000;
use strict;
use warnings;

use PerlGSL::DiffEq ':all';

use parent 'Exporter';
our @EXPORT = ( qw/ ode_solver / );
our @EXPORT_OK = ( qw/ get_gsl_version get_step_types / );

our %EXPORT_TAGS;
push @{$EXPORT_TAGS{all}}, @EXPORT, @EXPORT_OK;

our $VERSION = '0.08';
$VERSION = eval $VERSION;


1;

__END__
__POD__
=head1 NAME

Math::GSLx::ODEIV2 - DEPRECATED in favor of PerlGSL::DiffEq

=head1 DESCRIPTION

This module now serves to provide compatibility to users (are there any) of L<Math::GSLx::ODEIV2> which is now being developed and released as L<PerlGSL::DiffEq>. Please install that module.

=head2 NAMESPACE

Why the C<Math::GSLx::> namespace? Well since Jonathan Leto has been kind enough to SWIG the entire GSL library into the C<Math::GSL::> namespace I didn't want to confuse things by impling that this module was a part of that effort. The C<x> namespaces have become popular so I ran with it.

=head1 SEE ALSO

=over

=item L<PerlGSL::DiffEq>

=item L<PerlGSL>

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
