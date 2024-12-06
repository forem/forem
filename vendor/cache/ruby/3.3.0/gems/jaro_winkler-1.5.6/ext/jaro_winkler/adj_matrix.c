#include "adj_matrix.h"
#include "codepoints.h"
#include "ruby.h"

const char *DEFAULT_ADJ_TABLE[] = {
    "A", "E", "A", "I", "A", "O", "A", "U", "B", "V", "E", "I", "E",
    "O", "E", "U", "I", "O", "I", "U", "O", "U", "I", "Y", "E", "Y",
    "C", "G", "E", "F", "W", "U", "W", "V", "X", "K", "S", "Z", "X",
    "S", "Q", "C", "U", "V", "M", "N", "L", "I", "Q", "O", "P", "R",
    "I", "J", "2", "Z", "5", "S", "8", "B", "1", "I", "1", "L", "0",
    "O", "0", "Q", "C", "K", "G", "J", "E", " ", "Y", " ", "S", " "};

void node_free(Node *head);

AdjMatrix *adj_matrix_new(uint32_t length) {
  AdjMatrix *matrix = malloc(sizeof(AdjMatrix));
  matrix->length = length == 0 ? ADJ_MATRIX_DEFAULT_LENGTH : length;
  matrix->table = malloc(matrix->length * sizeof(Node **));
  for (size_t i = 0; i < matrix->length; i++) {
    matrix->table[i] = malloc(matrix->length * sizeof(Node *));
    for (size_t j = 0; j < matrix->length; j++)
      matrix->table[i][j] = NULL;
  }
  return matrix;
}

void adj_matrix_add(AdjMatrix *matrix, uint64_t x, uint64_t y) {
  uint32_t h1 = st_hash(&x, sizeof(x), ADJ_MATRIX_SEED) %
                ADJ_MATRIX_DEFAULT_LENGTH,
           h2 = st_hash(&y, sizeof(y), ADJ_MATRIX_SEED) %
                ADJ_MATRIX_DEFAULT_LENGTH;
  Node *new_node = malloc(sizeof(Node));
  new_node->x = h1;
  new_node->y = h2;
  new_node->next = NULL;
  if (matrix->table[h1][h2] == NULL) {
    matrix->table[h1][h2] = matrix->table[h2][h1] = new_node;
  } else {
    Node *previous = NULL;
    for (Node *i = matrix->table[h1][h2]; i != NULL; i = i->next)
      previous = i;
    previous->next = new_node;
  }
}

char adj_matrix_find(AdjMatrix *matrix, uint64_t x, uint64_t y) {
  uint32_t h1 = st_hash(&x, sizeof(x), ADJ_MATRIX_SEED) %
                ADJ_MATRIX_DEFAULT_LENGTH,
           h2 = st_hash(&y, sizeof(y), ADJ_MATRIX_SEED) %
                ADJ_MATRIX_DEFAULT_LENGTH;
  Node *node = matrix->table[h1][h2];
  if (node == NULL)
    return 0;
  else {
    for (Node *i = node; i != NULL; i = i->next)
      if ((i->x == h1 && i->y == h2) || (i->x == h2 && i->y == h1))
        return 1;
    return 0;
  }
}

void node_free(Node *head) {
  if (head == NULL)
    return;
  node_free(head->next);
  free(head);
}

void adj_matrix_free(AdjMatrix *matrix) {
  for (size_t i = 0; i < matrix->length; i++) {
    for (size_t j = 0; j < matrix->length; j++)
      if (matrix->table[i][j] != NULL) {
        node_free(matrix->table[i][j]);
        matrix->table[i][j] = matrix->table[j][i] = NULL;
      }
    free(matrix->table[i]);
  }
  free(matrix->table);
  free(matrix);
}

AdjMatrix *adj_matrix_default() {
  static char first_time = 1;
  static AdjMatrix *ret_matrix;
  if (first_time) {
    ret_matrix = adj_matrix_new(ADJ_MATRIX_DEFAULT_LENGTH);
    size_t length = sizeof(DEFAULT_ADJ_TABLE) / sizeof(char *);
    for (size_t i = 0; i < length; i += 2) {
      uint64_t code_1, code_2;
      code_1 = *DEFAULT_ADJ_TABLE[i] & 0xff;
      code_2 = *DEFAULT_ADJ_TABLE[i + 1] & 0xff;
      adj_matrix_add(ret_matrix, code_1, code_2);
    }
    first_time = 0;
  }
  return ret_matrix;
}
