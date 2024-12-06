#pragma once

#include "stdint.h"

#define ADJ_MATRIX_DEFAULT_LENGTH 958
#define ADJ_MATRIX_SEED 9527

typedef struct _node {
  struct _node *next;
  uint64_t x, y;
} Node;

typedef struct {
  Node ***table;
  uint32_t length;
} AdjMatrix;

AdjMatrix *adj_matrix_new(uint32_t length);
void adj_matrix_add(AdjMatrix *matrix, uint64_t x, uint64_t y);
char adj_matrix_find(AdjMatrix *matrix, uint64_t x, uint64_t y);
void adj_matrix_free(AdjMatrix *matrix);
AdjMatrix *adj_matrix_default();
