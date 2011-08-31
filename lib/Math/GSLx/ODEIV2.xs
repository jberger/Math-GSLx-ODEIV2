#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_version.h>

#include "common.h"

//--------------------------------------------
// These functions when properly replaced could implement a PDL backend

SV * make_container () {
  return newRV_noinc((SV*)newAV());
}

int store_data (SV* holder, int num, const double t, const double y[]) {
  int i;
  AV* data = newAV();

  av_push(data, newSVnv(t));
  for (i = 0; i < num; i++) {
    av_push(data, newSVnv(y[i]));
  }

  av_push((AV *)SvRV(holder), newRV_noinc((SV *)data));

  return 0;
}
//--------------------------------------------



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
