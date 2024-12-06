#include "jaro.h"
#include "adj_matrix.h"
#include "codepoints.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_WEIGHT 0.1
#define DEFAULT_THRESHOLD 0.7
#define SWAP(x, y)                                                             \
  do {                                                                         \
    __typeof__(x) SWAP = x;                                                    \
    x = y;                                                                     \
    y = SWAP;                                                                  \
  } while (0)

const Options DEFAULT_OPTIONS = {.weight = DEFAULT_WEIGHT,
                                 .threshold = DEFAULT_THRESHOLD,
                                 .ignore_case = 0,
                                 .adj_table = 0};

double jaro_distance_from_codes(uint32_t *codepoints1, size_t len1,
                                uint32_t *codepoints2, size_t len2,
                                Options *opt) {
  if (!len1 || !len2)
    return 0.0;

  if (len1 > len2) {
    SWAP(codepoints1, codepoints2);
    SWAP(len1, len2);
  }

  if (opt->ignore_case) {
    for (size_t i = 0; i < len1; i++)
      codepoints1[i] = tolower(codepoints1[i]);
    for (size_t i = 0; i < len2; i++)
      codepoints2[i] = tolower(codepoints2[i]);
  }

  int32_t window_size = (int32_t)len2 / 2 - 1;
  if (window_size < 0)
    window_size = 0;

  char short_codes_flag[len1];
  char long_codes_flag[len2];
  memset(short_codes_flag, 0, len1);
  memset(long_codes_flag, 0, len2);

  // count number of matching characters
  size_t match_count = 0;
  for (size_t i = 0; i < len1; i++) {
    size_t left = (i >= (size_t)window_size) ? i - window_size : 0;
    size_t right =
        (i + window_size <= len2 - 1) ? (i + window_size) : (len2 - 1);
    if (right > len2 - 1)
      right = len2 - 1;
    for (size_t j = left; j <= right; j++) {
      if (!long_codes_flag[j] && codepoints1[i] == codepoints2[j]) {
        short_codes_flag[i] = long_codes_flag[j] = 1;
        match_count++;
        break;
      }
    }
  }

  if (!match_count)
    return 0.0;

  // count number of transpositions
  size_t transposition_count = 0, j = 0, k = 0;
  for (size_t i = 0; i < len1; i++) {
    if (short_codes_flag[i]) {
      for (j = k; j < len2; j++) {
        if (long_codes_flag[j]) {
          k = j + 1;
          break;
        }
      }
      if (codepoints1[i] != codepoints2[j])
        transposition_count++;
    }
  }

  // count similarities in nonmatched characters
  size_t similar_count = 0;
  if (opt->adj_table && len1 > match_count)
    for (size_t i = 0; i < len1; i++)
      if (!short_codes_flag[i])
        for (size_t j = 0; j < len2; j++)
          if (!long_codes_flag[j])
            if (adj_matrix_find(adj_matrix_default(), codepoints1[i],
                                codepoints2[j])) {
              similar_count += 3;
              break;
            }

  double m = (double)match_count;
  double t = (double)(transposition_count / 2);
  if (opt->adj_table)
    m = similar_count / 10.0 + m;
  return (m / len1 + m / len2 + (m - t) / m) / 3;
}

double jaro_winkler_distance_from_codes(uint32_t *codepoints1, size_t len1,
                                        uint32_t *codepoints2, size_t len2,
                                        Options *opt) {
  double jaro_distance =
      jaro_distance_from_codes(codepoints1, len1, codepoints2, len2, opt);

  if (jaro_distance < opt->threshold)
    return jaro_distance;
  else {
    size_t prefix = 0;
    size_t max_4 = len1 > 4 ? 4 : len1;
    for (prefix = 0;
         prefix < max_4 && codepoints1[prefix] == codepoints2[prefix]; prefix++)
      ;
    return jaro_distance + prefix * opt->weight * (1 - jaro_distance);
  }
}
