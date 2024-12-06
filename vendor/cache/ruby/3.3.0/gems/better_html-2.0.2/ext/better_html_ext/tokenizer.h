#pragma once

enum tokenizer_context {
  TOKENIZER_NONE = 0,
  TOKENIZER_HTML,
  TOKENIZER_OPEN_TAG,
  TOKENIZER_SOLIDUS_OR_TAG_NAME,
  TOKENIZER_TAG_NAME,
  TOKENIZER_CDATA,
  TOKENIZER_RCDATA, // title, textarea
  TOKENIZER_RAWTEXT, // style, xmp, iframe, noembed, noframes
  TOKENIZER_SCRIPT_DATA, // script
  TOKENIZER_PLAINTEXT, // plaintext
  TOKENIZER_COMMENT,
  TOKENIZER_ATTRIBUTE_NAME,
  TOKENIZER_ATTRIBUTE_VALUE,
  TOKENIZER_ATTRIBUTE_UNQUOTED,
  TOKENIZER_ATTRIBUTE_QUOTED,
};

enum token_type {
  TOKEN_NONE = 0,
  TOKEN_TEXT,
  TOKEN_WHITESPACE,
  TOKEN_COMMENT_START,
  TOKEN_COMMENT_END,
  TOKEN_TAG_START,
  TOKEN_TAG_NAME,
  TOKEN_TAG_END,
  TOKEN_ATTRIBUTE_NAME,
  TOKEN_ATTRIBUTE_QUOTED_VALUE_START,
  TOKEN_ATTRIBUTE_QUOTED_VALUE,
  TOKEN_ATTRIBUTE_QUOTED_VALUE_END,
  TOKEN_ATTRIBUTE_UNQUOTED_VALUE,
  TOKEN_CDATA_START,
  TOKEN_CDATA_END,
  TOKEN_SOLIDUS,
  TOKEN_EQUAL,
  TOKEN_MALFORMED,
};

struct scan_t {
  char *string;
  long unsigned int cursor;
  long unsigned int length;

  int enc_index;
  long unsigned int mb_cursor;
};

struct tokenizer_t
{
  enum tokenizer_context context[1000];
  uint32_t current_context;

  void *callback_data;
  void (*f_callback)(struct tokenizer_t *tk, enum token_type type, long unsigned int length, void *data);

  char attribute_value_start;
  int found_attribute;

  char *current_tag;

  int is_closing_tag;
  enum token_type last_token;

  struct scan_t scan;
};


void Init_html_tokenizer_tokenizer(VALUE mHtmlTokenizer);
void tokenizer_init(struct tokenizer_t *tk);
void tokenizer_free_members(struct tokenizer_t *tk);
void tokenizer_set_scan_string(struct tokenizer_t *tk, const char *string, long unsigned int length);
void tokenizer_free_scan_string(struct tokenizer_t *tk);
void tokenizer_scan_all(struct tokenizer_t *tk);
VALUE token_type_to_symbol(enum token_type type);

extern const rb_data_type_t ht_tokenizer_data_type;
#define Tokenizer_Get_Struct(obj, sval) TypedData_Get_Struct(obj, struct tokenizer_t, &ht_tokenizer_data_type, sval)
