#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_version.h>

char* get_gsl_version () {
  return GSL_VERSION;
}

struct params {
  int num;
  SV* eqn;
};

int diff_eqs (double t, const double y[], double f[], void *params) {

  dSP;

  SV* eqn = ((struct params *)params)->eqn;
  int num = ((struct params *)params)->num;
  int count;
  int i;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSVnv(t)));

  for (i = 1; i <= num; i++) {
    XPUSHs(sv_2mortal(newSVnv(y[i-1])));
  }
  PUTBACK;

  count = call_sv(eqn, G_ARRAY);
  if (count != num) 
    warn("Equation did not return the specified number of values");

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    f[num-i] = POPn;
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  return GSL_SUCCESS;

}

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

/* c_ode_solver needs stack to be clear when called,
   I recommend `local @_;` before calling. */
SV* c_ode_solver
  (SV* eqn, double t1, double t2, int steps, int step_type_num, double h_step,
    double epsabs, double epsrel, double a_y, double a_dydt) {

  dSP;

  int num;
  int i;
  double t = t1;
  double * y;
  SV* ret = make_container();
  const gsl_odeiv2_step_type * step_type;

  // create step_type_num, selected with $opt->{type}
  // then .pm converts user choice to number
  if (step_type_num == 1) {
    step_type = gsl_odeiv2_step_rk2;
  } else if (step_type_num == 2) {
    step_type = gsl_odeiv2_step_rk4;
  } else if (step_type_num == 3) {
    step_type = gsl_odeiv2_step_rkf45;
  } else if (step_type_num == 4) {
    step_type = gsl_odeiv2_step_rkck;
  } else if (step_type_num == 5) {
    step_type = gsl_odeiv2_step_rk8pd;
  } else {
    warn("Could not determine step type, using rk8pd");
    step_type = gsl_odeiv2_step_rk8pd;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  num = call_sv(eqn, G_ARRAY|G_NOARGS);
  New(1, y, num, double);

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    y[num-i] = POPn;
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  store_data(ret, num, t, y);

  struct params myparams;
  myparams.num = num;
  myparams.eqn = eqn;

  gsl_odeiv2_system sys = {diff_eqs, NULL, num, &myparams};
     
  gsl_odeiv2_driver * d = 
    gsl_odeiv2_driver_alloc_standard_new (
      &sys, step_type, h_step, epsabs, epsrel, a_y, a_dydt
    );
     
  for (i = 1; i <= steps; i++)
    {
      double ti = i * t2 / steps;
      int status = gsl_odeiv2_driver_apply (d, &t, ti, y);
     
      if (status != GSL_SUCCESS)
        {
          warn("error, return value=%d\n", status);
          break;
        }

      /* At this point I envision that PDL could be used to store the data
         rather than creating tons of SVs. Of course the current behavior
         should remain for those systems without PDL */

      store_data(ret, num, t, y);
    }
     
  gsl_odeiv2_driver_free(d);
  Safefree(y);

  return ret;
}


MODULE = Math::GSLx::ODEIV2	PACKAGE = Math::GSLx::ODEIV2	

PROTOTYPES: DISABLE


char *
get_gsl_version ()

SV *
c_ode_solver (eqn, t1, t2, steps, step_type_num, h_step, epsabs, epsrel, a_y, a_dydt)
	SV *	eqn
	double	t1
	double	t2
	int	steps
	int	step_type_num
	double	h_step
	double	epsabs
	double	epsrel
	double	a_y
	double	a_dydt
