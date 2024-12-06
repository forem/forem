#include "codepoints.h"
#include "jaro.h"
#include "ruby.h"

VALUE rb_mJaroWinkler, rb_eError, rb_eInvalidWeightError;

VALUE rb_jaro_winkler_distance(int argc, VALUE *argv, VALUE self);
VALUE rb_jaro_distance(int argc, VALUE *argv, VALUE self);
VALUE distance(int argc, VALUE *argv, VALUE self,
               double (*distance_fn)(uint32_t *codepoints1, size_t len1,
                                     uint32_t *codepoints2, size_t len2,
                                     Options *));

void Init_jaro_winkler_ext(void) {

#ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
#endif

  rb_mJaroWinkler = rb_define_module("JaroWinkler");
  rb_eError = rb_define_class_under(rb_mJaroWinkler, "Error", rb_eRuntimeError);
  rb_eInvalidWeightError =
      rb_define_class_under(rb_mJaroWinkler, "InvalidWeightError", rb_eError);
  rb_define_singleton_method(rb_mJaroWinkler, "distance",
                             rb_jaro_winkler_distance, -1);
  rb_define_singleton_method(rb_mJaroWinkler, "jaro_distance", rb_jaro_distance,
                             -1);
}

VALUE distance(int argc, VALUE *argv, VALUE self,
               double (*distance_fn)(uint32_t *codepoints1, size_t len1,
                                     uint32_t *codepoints2, size_t len2,
                                     Options *)) {
  VALUE s1, s2, opt;

  rb_scan_args(argc, argv, "2:", &s1, &s2, &opt);

  Check_Type(s1, T_STRING);
  Check_Type(s2, T_STRING);
  Options c_opt = DEFAULT_OPTIONS;
  if (TYPE(opt) == T_HASH) {
    VALUE weight = rb_hash_aref(opt, ID2SYM(rb_intern("weight"))),
          threshold = rb_hash_aref(opt, ID2SYM(rb_intern("threshold"))),
          ignore_case = rb_hash_aref(opt, ID2SYM(rb_intern("ignore_case"))),
          adj_table = rb_hash_aref(opt, ID2SYM(rb_intern("adj_table")));
    if (!NIL_P(weight))
      c_opt.weight = NUM2DBL(weight);
    if (c_opt.weight > 0.25)
      rb_raise(rb_eInvalidWeightError, "Scaling factor should not exceed 0.25, "
                                       "otherwise the distance can become "
                                       "larger than 1.");
    if (!NIL_P(threshold))
      c_opt.threshold = NUM2DBL(threshold);
    if (!NIL_P(ignore_case))
      c_opt.ignore_case =
          (TYPE(ignore_case) == T_FALSE || NIL_P(ignore_case)) ? 0 : 1;
    if (!NIL_P(adj_table))
      c_opt.adj_table =
          (TYPE(adj_table) == T_FALSE || NIL_P(adj_table)) ? 0 : 1;
  }
  CodePoints cp1, cp2;
  codepoints_init(&cp1, s1);
  codepoints_init(&cp2, s2);
  VALUE ret = rb_float_new(
      (*distance_fn)(cp1.data, cp1.length, cp2.data, cp2.length, &c_opt));
  codepoints_free(&cp1);
  codepoints_free(&cp2);
  return ret;
}

VALUE rb_jaro_distance(int argc, VALUE *argv, VALUE self) {
  return distance(argc, argv, self, jaro_distance_from_codes);
}

VALUE rb_jaro_winkler_distance(int argc, VALUE *argv, VALUE self) {
  return distance(argc, argv, self, jaro_winkler_distance_from_codes);
}
