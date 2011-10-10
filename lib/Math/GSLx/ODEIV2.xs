#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common.h"

MODULE = Math::GSLx::ODEIV2	PACKAGE = Math::GSLx::ODEIV2	

PROTOTYPES: DISABLE


char *
get_gsl_version ()

SV *
c_ode_solver (eqn, jac, t1, t2, steps, step_type_num, h_init, h_max, epsabs, epsrel, a_y, a_dydt)
	SV *	eqn
	SV *	jac
	double	t1
	double	t2
	int	steps
	int	step_type_num
	double	h_init
	double  h_max
	double	epsabs
	double	epsrel
	double	a_y
	double	a_dydt
