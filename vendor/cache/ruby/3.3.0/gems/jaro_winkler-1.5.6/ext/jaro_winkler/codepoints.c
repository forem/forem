#include "codepoints.h"
#include "ruby.h"
#include "ruby/encoding.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// this function is copied from string.c
static inline int single_byte_optimizable(VALUE str) {
  rb_encoding *enc;

  /* Conservative.  It may be ENC_CODERANGE_UNKNOWN. */
  if (ENC_CODERANGE(str) == ENC_CODERANGE_7BIT)
    return 1;

  enc = rb_enc_get(str);
  if (rb_enc_mbmaxlen(enc) == 1)
    return 1;

  /* Conservative.  Possibly single byte.
   * "\xa1" in Shift_JIS for example. */
  return 0;
}

void codepoints_init(CodePoints *codepoints, VALUE str) {
  size_t i, length;
  int32_t n;
  uint32_t c;
  const char *ptr, *end;
  rb_encoding *enc;

  if (single_byte_optimizable(str)) {
    length = RSTRING_LEN(str);
    ptr = RSTRING_PTR(str);
    codepoints->data = malloc(length * sizeof(*codepoints->data));
    for (i = 0, codepoints->length = 0; i < length; i++, codepoints->length++)
      codepoints->data[i] = ptr[i] & 0xff;
  } else {
    codepoints->length = 0;
    codepoints->size = 32;
    codepoints->data = malloc(codepoints->size * sizeof(*codepoints->data));
    str = rb_str_new_frozen(str);
    ptr = RSTRING_PTR(str);
    end = RSTRING_END(str);
    enc = rb_enc_get(str);

    while (ptr < end) {
      c = rb_enc_codepoint_len(ptr, end, &n, enc);
      if (codepoints->length == codepoints->size) {
        codepoints->size *= 2;
        codepoints->data = realloc(codepoints->data, sizeof(*codepoints->data) *
                                                         codepoints->size);
      }
      codepoints->data[codepoints->length++] = c;
      ptr += n;
    }
    RB_GC_GUARD(str);
  }
}

void codepoints_free(CodePoints *codepoints) { free(codepoints->data); }
