
/*
 * Enable C99 extensions to enable fast float rounding stuff in math.h.
 */
#define	_ISOC9X_SOURCE	1
#define _ISOC99_SOURCE	1

#include <math.h>
#include <ruby.h>
#include <time.h>

#define FLOOR(a) lrintf(floorf(a))
#define FLOAT(a) (float)a

static VALUE rb_cDate;      /* class Date */
static VALUE rb_cRational;  /* class Rational */

static ID id_subtract;      /* :- */
static ID id_add;           /* :+ */
static ID id_divmod;        /* :divmod */
static ID id_new;           /* :new */
static ID id_new_bang;      /* :new! */
static ID id_ivar_civil;    /* :@__civil__ */
static ID id_jd;            /* :jd */
static ID id_ivar_ajd;      /* :@ajd */
static ID id_jd_to_civil;   /* :jd_to_civil */
static ID id_ivar_sg;       /* :@sg */
static ID id_numerator;     /* :numerator */
static ID id_denominator;   /* :denominator */

static ID id_strptime_without_performance;
static ID id_strftime_without_performance;

static VALUE JULIAN;        /* Date::JULIAN */
static VALUE GREGORIAN;     /* Date::GREGORIAN */
static VALUE ITALY;         /* Date::ITALY */

static VALUE ra_one_half;    /* Rational(1, 2) */
static VALUE DEFAULT_FORMAT; /* "%F" */

static int initialized = 0;

static inline int 
civil_to_jd(int y, int m, int d, VALUE sg)
{
  int a, b, jd;
  if ( m <= 2 ) {
    y-= 1;
    m+= 12;
  }
  a = y / 100;
  b = 2 - a + (a / 4);
  jd = FLOOR(365.25 * (y + 4716)) +
    FLOOR(30.6001 * (m + 1)) +
    d + b - 1524;
  if ( sg == JULIAN || (sg != GREGORIAN && jd < FIX2INT(sg)) )
    jd -= b;
  return jd;
}


/*
 * Date::civil_to_jd(year, month, day, sg=Date::GREGORIAN)
 */
static VALUE 
rb_date_civil_to_jd(int argc, VALUE* argv, VALUE self)
{
  int y  = FIX2INT(argv[0]), 
      m  = FIX2INT(argv[1]), 
      d  = FIX2INT(argv[2]);
  VALUE sg = (argc == 4 ? argv[3] : GREGORIAN);
  return INT2FIX(civil_to_jd(y, m, d, sg));
}


struct mini_tm {
  int y;
  int m;
  int d;
};


static inline void
jd_to_civil(int jd, VALUE sg, struct mini_tm * t)
{
  int a, b, c, d, e;
  if ( sg == JULIAN || (sg != GREGORIAN && jd < FIX2INT(sg)) ) { /* julian? */
    a = jd;
  }else{
    int x = FLOOR((jd - 1867216.25) / 36524.25);
    a = jd + 1 + x - FLOOR(x / 4.0);
  }
  b = a + 1524;
  c = FLOOR((b - 122.1) / 365.25);
  d = FLOOR(365.25 * c);
  e = FLOOR((b - d) / 30.6001);
  t->d = b - d - FLOOR(30.6001 * e);
  if ( e <= 13 ) {
    t->m = e - 1;
    t->y = c - 4716;
  }else{
    t->m = e - 13;
    t->y = c - 4715;
  }
}


/*
 * Date::jd_to_civil(jd, sg=GREGORIAN)
 */
static VALUE 
rb_date_jd_to_civil(int argc, VALUE * argv, VALUE self)
{
  int    jd = FIX2INT(argv[0]);
  VALUE  sg = (argc == 2 ? argv[1] : GREGORIAN);
  struct mini_tm t;
  jd_to_civil(jd, sg, &t);
  return rb_ary_new3(3, INT2FIX(t.y), INT2FIX(t.m), INT2FIX(t.d));
}


/*
 * Calculate the AJD from a julian date, fractional day, and offset.
 */
static inline VALUE
jd_to_ajd(long jd, VALUE fr, VALUE of)
{
  /* Ruby Implementation: jd + fr - of - 1.to_r/2 */
  if ( TYPE(fr) == T_FIXNUM && TYPE(of) == T_FIXNUM ) {
    /* fast path the common case of no fraction and no offset */
    long numerator = (((jd + FIX2LONG(fr) - FIX2LONG(of)) - 1) * 2) + 1;
    return rb_funcall(rb_cRational, id_new, 2, LONG2FIX(numerator), LONG2FIX(2));
  }else{
    /* use slower rational math */
    VALUE result = rb_funcall(rb_cRational, id_new, 2, LONG2FIX(jd), LONG2FIX(1));
    result = rb_funcall(result, id_add, 1, fr);
    if ( of != LONG2FIX(0) ) 
      result = rb_funcall(result, id_subtract, 1, of);
    result = rb_funcall(result, id_subtract, 1, ra_one_half);
    return result;
  }
}


/*
 * Date::jd_to_ajd(jd, fr, of=0)
 */
static VALUE
rb_date_jd_to_ajd(int argc, VALUE * argv, VALUE self)
{
  long jd = FIX2LONG(argv[0]);
  VALUE fr = (argc > 1 ? argv[1] : LONG2FIX(0));
  VALUE of = (argc > 2 ? argv[2] : LONG2FIX(0));
  return jd_to_ajd(jd, fr, of);
}


/*
 * Date::ajd_to_jd(ajd, of=0)
 *
 * TODO: handle offsets properly.
 *
 * Ruby Implementation: (ajd + of + 1.to_r/2).divmod(1)
 */
static VALUE
rb_date_ajd_to_jd(int argc, VALUE * argv, VALUE self)
{
  VALUE ajd = argv[0];
  VALUE of  = (argc == 2 ? argv[1] : INT2FIX(0));
  long den = FIX2LONG(rb_funcall(ajd, id_denominator, 0));
  long num = FIX2LONG(rb_funcall(ajd, id_numerator, 0));
  if ( den == 2 && of == INT2FIX(0) ) {
    /* fast path */
    return rb_ary_new3(2, LONG2FIX((num + 1) / 2), ra_one_half);
  }else{
    VALUE result = rb_funcall(ajd, id_add, 1, of);
    result = rb_funcall(result, id_add, 1, ra_one_half);
    return rb_funcall(result, id_divmod, 1, LONG2FIX(1));
  }
}


/*
 * Date::new(y=-4712, m=1, d=1, sg=ITALY)
 */
static VALUE 
rb_date_new(int argc, VALUE * argv, VALUE self) {
  int y    = (argc > 0 ? NUM2INT(argv[0]) : -4712),
      m    = (argc > 1 ? NUM2INT(argv[1]) : 1),
      d    = (argc > 2 ? NUM2INT(argv[2]) : 1);
  VALUE sg = (argc > 3 ? argv[3] : ITALY);
  int jd = -1;
  struct mini_tm t;
  if (d < 0) {
    int ny = (y * 12 + m) / 12;
    int nm = (y * 12 + m) % 12;
    nm = (nm + 1) / 1;
    jd = civil_to_jd(ny, nm, d+1, sg);

    VALUE ns = jd < 2299161 ? JULIAN : GREGORIAN;
    jd_to_civil(jd-d, ns, &t);
    if ( t.y != ny || t.m != nm || t.d != 1 ) {
      rb_raise(rb_eArgError, "Invalid date: (%d, %d, %d)", y, m, d);
      return Qnil;
    }
    jd_to_civil(jd, sg, &t);
    if ( t.y != y || t.m != m ) {
      rb_raise(rb_eArgError, "Invalid date: (%d, %d, %d)", y, m, d);
      return Qnil;
    }
  } else {
    jd = civil_to_jd(y, m, d, sg);
    jd_to_civil(jd, sg, &t);
    if ( t.y != y || t.m != m || t.d != d ) {
      rb_raise(rb_eArgError, "Invalid date: (%d, %d, %d)", y, m, d);
      return Qnil;
    }
  }
  VALUE ajd = jd_to_ajd(jd, INT2FIX(0), INT2FIX(0));
  VALUE date = rb_funcall(self, id_new_bang, 3, ajd, INT2FIX(0), sg);
  rb_ivar_set(date, id_ivar_civil, rb_ary_new3(3, INT2FIX(t.y), INT2FIX(t.m), INT2FIX(t.d)));
  return date;
}


/*
 * Date#civil
 *
 * Fast path the case where the date is created with civil parameters.
 */
static VALUE
rb_date_civil(VALUE self) {
  if ( rb_ivar_defined(self, id_ivar_civil) == Qfalse ) {
    VALUE jd = rb_funcall(self, id_jd, 0);
    VALUE sg = rb_ivar_get(self, id_ivar_sg);
    VALUE result = rb_funcall(rb_cDate, id_jd_to_civil, 2, jd, sg);
    return rb_ivar_set(self, id_ivar_civil, result);
  }else{
    return rb_ivar_get(self, id_ivar_civil);
  }
}


/*
 * Date#sys_strftime(fmt="%F")
 */
static VALUE
rb_date_strftime(int argc, VALUE * argv, VALUE self)
{
  VALUE format = (argc > 0 ? *argv : DEFAULT_FORMAT);
  VALUE civil = rb_date_civil(self);

  char  * pf = RSTRING(format)->ptr;
  VALUE * pc = RARRAY(civil)->ptr;
  int ic[3];

  ic[0] = FIX2INT(pc[0]);
  ic[1] = FIX2INT(pc[1]);
  ic[2] = FIX2INT(pc[2]);

  /* fast path default format: %F or %Y-%m-%d */
  if ( (pf[0] == '%' && pf[1] == 'F' && pf[2] == 0) ||
       (pf[0] == '%' && pf[1] == 'Y' && pf[2] == '-' 
     && pf[3] == '%' && pf[4] == 'm' && pf[5] == '-'
     && pf[6] == '%' && pf[7] == 'd' && pf[8] == 0) )
  {
    VALUE buf = rb_str_buf_new(11);
    char  * pb = RSTRING(buf)->ptr;
    RSTRING(buf)->len = 
      sprintf(pb, "%04d-%02d-%02d", ic[0], ic[1], ic[2]);
    return buf;
  }
 
  /* Use libc's strftime but only for Date class */
  if ( RBASIC(self)->klass == rb_cDate ){
    VALUE buf = rb_str_buf_new(128);
    char  * pb = RSTRING(buf)->ptr;
    struct tm t;
    bzero(&t, sizeof(struct tm));
    t.tm_year = ic[0] - 1900;
    t.tm_mon  = ic[1] - 1;
    t.tm_mday = ic[2];
    mktime(&t);  /* fill in missing items (tm_wday, tm_yday) */
    if ( (RSTRING(buf)->len = strftime(pb, 128, pf, &t)) > 0 )
      return buf;
  }

  /* fall back on Ruby implementation if libc's strftime fails */
  return rb_funcall2(self, id_strftime_without_performance, argc, argv);
}


/*
 * Date::strptime(str="-4712-01-01", fmt='%F')
 */
static VALUE
rb_date_strptime(int argc, VALUE * argv, VALUE self)
{
  char *pe;
  struct tm buf;
  VALUE str = (argc > 0 ? argv[0] : rb_str_new2("-4712-01-01")),
        fmt = (argc > 1 ? argv[1] : DEFAULT_FORMAT),
        sg  = (argc > 2 ? argv[2] : ITALY);
  char * ps = RSTRING(str)->ptr;
  char * pf = RSTRING(fmt)->ptr;
  VALUE parts[4];

  /* fast path default format */
  if ( (pf[0] == '%' && pf[1] == 'F' && pf[0])
    || (pf[0] == '%' && pf[1] == 'Y' && pf[2] == '-' 
     && pf[3] == '%' && pf[4] == 'm' && pf[5] == '-'
     && pf[6] == '%' && pf[7] == 'd' && pf[8] == 0) )
  {
    parts[0] = INT2FIX(strtol(ps, &pe, 10));
    parts[1] = Qnil;
    parts[2] = Qnil; 
    parts[3] = sg;
    if( pe == ps + 4 )  { 
      parts[1] = INT2FIX(strtol(ps + 5, &pe, 10));
      if ( pe == ps + 7 ) { 
        parts[2] = INT2FIX(strtol(ps + 8, &pe, 10));
        if ( pe == ps + 10 )
          return rb_date_new(4, (VALUE*)&parts, self);
      }
    }
  }

  /* fall back on strptime(3) */
  if ( strptime(ps, pf, &buf) )
  {
    parts[0] = INT2FIX(buf.tm_year + 1900);
    parts[1] = INT2FIX(buf.tm_mon  + 1);
    parts[2] = INT2FIX(buf.tm_mday);
    parts[3] = sg;
    return rb_date_new(4, (VALUE*)&parts, self);
  }

  /* if that doesn't work, fall back on Ruby implementation */
  return rb_funcall2(self, id_strptime_without_performance, argc, argv);
}

/*
 * Date::<=>(other)
*/
static VALUE
rb_date_compare(int argc, VALUE * argv, VALUE self)
{
  if (NIL_P(argv[0]))
    return Qnil;
  long other_den = -1;
  long other_num = -1;
  if (FIXNUM_P(argv[0])) {
    //compare with argument as with astronomical julian day number
    other_den = 1;
    other_num = FIX2LONG(argv[0]);
  } else if (rb_obj_is_kind_of(argv[0], rb_cDate)) {
    VALUE other_date = argv[0];
    VALUE other_ajd = rb_ivar_get(other_date, id_ivar_ajd);
    other_den = FIX2LONG(rb_funcall(other_ajd, id_denominator, 0));
    other_num = FIX2LONG(rb_funcall(other_ajd, id_numerator, 0));
  } else {
    return Qnil;
  }
  
  VALUE ajd = rb_ivar_get(self, id_ivar_ajd);
  long den = FIX2LONG(rb_funcall(ajd, id_denominator, 0));
  long num = FIX2LONG(rb_funcall(ajd, id_numerator, 0));

  long v = (num * other_den) - (other_num * den);
  if (v > 0)
    return INT2FIX(1);
  else if (v < 0)
    return INT2FIX(-1);
  else
    return INT2FIX(0);
}


VALUE
Init_date_performance() {
  /* initialization is not idemponent - make sure it only happens once. */
  if ( initialized )
    rb_raise(rb_eStandardError, "date_performance extension already initialized.");
  initialized = 1;

  /* Grab Date class */
  rb_require("date");
  rb_cDate = rb_define_class("Date", rb_cObject);
  
  if( ! rb_const_defined_from(rb_cDate, rb_intern("Performance")) ) 
    rb_raise(rb_eStandardError, 
        "Date::Performance not defined. The date_performance extension can not be required directly.");

  /* Date Instance Methods */
  rb_define_method(rb_cDate, "civil",        rb_date_civil, 0);
  rb_define_method(rb_cDate, "sys_strftime", rb_date_strftime, -1);
  rb_define_method(rb_cDate, "strftime",     rb_date_strftime, -1);
  rb_define_method(rb_cDate, "<=>",          rb_date_compare, -1);

  /* Date Singleton Methods */
  rb_define_singleton_method(rb_cDate, "civil_to_jd",   rb_date_civil_to_jd, -1);
  rb_define_singleton_method(rb_cDate, "jd_to_civil",   rb_date_jd_to_civil, -1);
  rb_define_singleton_method(rb_cDate, "jd_to_ajd",     rb_date_jd_to_ajd, -1);
  rb_define_singleton_method(rb_cDate, "ajd_to_jd",     rb_date_ajd_to_jd, -1);
  rb_define_singleton_method(rb_cDate, "new",           rb_date_new, -1);
  rb_define_singleton_method(rb_cDate, "civil",         rb_date_new, -1);
  rb_define_singleton_method(rb_cDate, "sys_strptime",  rb_date_strptime, -1);
  rb_define_singleton_method(rb_cDate, "strptime",      rb_date_strptime, -1);

  /* Date Related Constants */
  JULIAN = rb_eval_string("Date::JULIAN");
  GREGORIAN = rb_eval_string("Date::GREGORIAN");
  ITALY = INT2FIX(2299161);

  DEFAULT_FORMAT = rb_str_new2("%F");
  rb_gc_register_address(&DEFAULT_FORMAT);

  /* Symbol Constants */
  id_subtract = rb_intern("-");
  id_add = rb_intern("+");
  id_divmod = rb_intern("divmod");
  id_new = rb_intern("new");
  id_jd = rb_intern("jd");
  id_ivar_ajd = rb_intern("@ajd");
  id_jd_to_civil = rb_intern("jd_to_civil");
  id_ivar_civil = rb_intern("@__civil__");
  id_ivar_sg = rb_intern("@sg");
  id_new_bang = rb_intern("new!");
  id_numerator = rb_intern("numerator");
  id_denominator = rb_intern("denominator");
  id_strptime_without_performance = rb_intern("strptime_without_performance");
  id_strftime_without_performance = rb_intern("strftime_without_performance");

  /* Rational Stuff */
  rb_require("rational");
  rb_cRational = rb_define_class("Rational", rb_cNumeric);
  ra_one_half = rb_funcall(rb_cRational, id_new, 2, INT2FIX(1), INT2FIX(2));
  rb_gc_register_address(&ra_one_half);
  return Qnil;
}
