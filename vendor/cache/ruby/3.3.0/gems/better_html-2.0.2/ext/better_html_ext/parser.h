#pragma once
#include "tokenizer.h"

enum parser_context {
  PARSER_NONE,
  PARSER_SOLIDUS_OR_TAG_NAME,
  PARSER_TAG_NAME,
  PARSER_TAG,
  PARSER_ATTRIBUTE_NAME,
  PARSER_ATTRIBUTE_WHITESPACE_OR_EQUAL,
  PARSER_ATTRIBUTE_WHITESPACE_OR_VALUE,
  PARSER_ATTRIBUTE_QUOTED_VALUE,
  PARSER_SPACE_AFTER_ATTRIBUTE,
  PARSER_ATTRIBUTE_UNQUOTED_VALUE,
  PARSER_TAG_END,
  PARSER_COMMENT,
  PARSER_CDATA,
};

struct parser_document_error_t {
  char *message;
  long unsigned int pos;
  long unsigned int mb_pos;
  long unsigned int line_number;
  long unsigned int column_number;
};

struct parser_document_t {
  long unsigned int length;
  char *data;
  long unsigned int line_number;
  long unsigned int column_number;

  int enc_index;
  long unsigned int mb_length;
};

struct token_reference_t {
  enum token_type type;
  long unsigned int start;
  long unsigned int mb_start;
  long unsigned int length;
  long unsigned int line_number;
  long unsigned int column_number;
};

struct parser_tag_t {
  struct token_reference_t name;
  int self_closing;
};

struct parser_attribute_t {
  struct token_reference_t name;
  struct token_reference_t value;
  int is_quoted;
};

struct parser_rawtext_t {
  struct token_reference_t text;
};

struct parser_comment_t {
  struct token_reference_t text;
};

struct parser_cdata_t {
  struct token_reference_t text;
};

struct parser_t
{
  struct tokenizer_t tk;

  struct parser_document_t doc;

  size_t errors_count;
  struct parser_document_error_t *errors;

  enum parser_context context;
  struct parser_tag_t tag;
  struct parser_attribute_t attribute;
  struct parser_rawtext_t rawtext;
  struct parser_comment_t comment;
  struct parser_cdata_t cdata;
};

void Init_html_tokenizer_parser(VALUE mHtmlTokenizer);

extern const rb_data_type_t ht_parser_data_type;
#define Parser_Get_Struct(obj, sval) TypedData_Get_Struct(obj, struct parser_t, &ht_parser_data_type, sval)

#define PARSE_AGAIN return 1
#define PARSE_DONE return 0
