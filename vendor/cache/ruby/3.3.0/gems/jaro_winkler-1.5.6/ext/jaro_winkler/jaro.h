#pragma once

#include <stddef.h>
#include <stdint.h>

typedef struct {
  double weight, threshold;
  char ignore_case, adj_table;
} Options;

extern const Options DEFAULT_OPTIONS;

double jaro_distance_from_codes(uint32_t *codepoints1, size_t len1,
                                uint32_t *codepoints2, size_t len2, Options *);
double jaro_winkler_distance_from_codes(uint32_t *codepoints1, size_t len1,
                                        uint32_t *codepoints2, size_t len2,
                                        Options *);
