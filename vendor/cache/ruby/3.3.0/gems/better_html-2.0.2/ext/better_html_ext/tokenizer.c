#include <ruby.h>
#include <ruby/encoding.h>
#include "html_tokenizer.h"
#include "tokenizer.h"

static VALUE cTokenizer = Qnil;

static void tokenizer_mark(void *ptr)
{}

static void tokenizer_free(void *ptr)
{
  struct tokenizer_t *tk = ptr;
  if(tk) {
    tokenizer_free_members(tk);
    DBG_PRINT("tk=%p xfree(tk)", tk);
    xfree(tk);
  }
}

static size_t tokenizer_memsize(const void *ptr)
{
  return ptr ? sizeof(struct tokenizer_t) : 0;
}

const rb_data_type_t ht_tokenizer_data_type = {
  "ht_tokenizer_data_type",
  { tokenizer_mark, tokenizer_free, tokenizer_memsize, },
#if defined(RUBY_TYPED_FREE_IMMEDIATELY)
  NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static VALUE tokenizer_allocate(VALUE klass)
{
  VALUE obj;
  struct tokenizer_t *tokenizer = NULL;

  obj = TypedData_Make_Struct(klass, struct tokenizer_t, &ht_tokenizer_data_type, tokenizer);
  DBG_PRINT("tk=%p allocate", tokenizer);

  memset((void *)&tokenizer->context, TOKENIZER_NONE, sizeof(struct tokenizer_t));

  return obj;
}

void tokenizer_init(struct tokenizer_t *tk)
{
  tk->current_context = 0;
  tk->context[0] = TOKENIZER_HTML;

  tk->scan.string = NULL;
  tk->scan.cursor = 0;
  tk->scan.length = 0;
  tk->scan.mb_cursor = 0;
  tk->scan.enc_index = 0;

  tk->attribute_value_start = 0;
  tk->found_attribute = 0;
  tk->current_tag = NULL;
  tk->is_closing_tag = 0;
  tk->last_token = TOKEN_NONE;
  tk->callback_data = NULL;
  tk->f_callback = NULL;

  return;
}

void tokenizer_free_members(struct tokenizer_t *tk)
{
  if(tk->current_tag) {
    DBG_PRINT("tk=%p xfree(tk->current_tag) %p", tk, tk->current_tag);
    xfree(tk->current_tag);
    tk->current_tag = NULL;
  }
  if(tk->scan.string) {
    DBG_PRINT("tk=%p xfree(tk->scan.string) %p", tk, tk->scan.string);
    xfree(tk->scan.string);
    tk->scan.string = NULL;
  }
  return;
}

VALUE token_type_to_symbol(enum token_type type)
{
  switch(type) {
  case TOKEN_NONE:
    return ID2SYM(rb_intern("none"));
  case TOKEN_TEXT:
    return ID2SYM(rb_intern("text"));
  case TOKEN_WHITESPACE:
    return ID2SYM(rb_intern("whitespace"));
  case TOKEN_COMMENT_START:
    return ID2SYM(rb_intern("comment_start"));
  case TOKEN_COMMENT_END:
    return ID2SYM(rb_intern("comment_end"));
  case TOKEN_TAG_NAME:
    return ID2SYM(rb_intern("tag_name"));
  case TOKEN_TAG_START:
    return ID2SYM(rb_intern("tag_start"));
  case TOKEN_TAG_END:
    return ID2SYM(rb_intern("tag_end"));
  case TOKEN_ATTRIBUTE_NAME:
    return ID2SYM(rb_intern("attribute_name"));
  case TOKEN_ATTRIBUTE_QUOTED_VALUE_START:
    return ID2SYM(rb_intern("attribute_quoted_value_start"));
  case TOKEN_ATTRIBUTE_QUOTED_VALUE:
    return ID2SYM(rb_intern("attribute_quoted_value"));
  case TOKEN_ATTRIBUTE_QUOTED_VALUE_END:
    return ID2SYM(rb_intern("attribute_quoted_value_end"));
  case TOKEN_ATTRIBUTE_UNQUOTED_VALUE:
    return ID2SYM(rb_intern("attribute_unquoted_value"));
  case TOKEN_CDATA_START:
    return ID2SYM(rb_intern("cdata_start"));
  case TOKEN_CDATA_END:
    return ID2SYM(rb_intern("cdata_end"));
  case TOKEN_SOLIDUS:
    return ID2SYM(rb_intern("solidus"));
  case TOKEN_EQUAL:
    return ID2SYM(rb_intern("equal"));
  case TOKEN_MALFORMED:
    return ID2SYM(rb_intern("malformed"));
  }
  return Qnil;
}

static long unsigned int tokenizer_mblength(struct tokenizer_t *tk, long unsigned int length)
{
  rb_encoding *enc = rb_enc_from_index(tk->scan.enc_index);
  const char *buf = tk->scan.string + tk->scan.cursor;
  return rb_enc_strlen(buf, buf + length, enc);
}

static void tokenizer_yield_tag(struct tokenizer_t *tk, enum token_type type, long unsigned int length, void *data)
{
  long unsigned int mb_length = tokenizer_mblength(tk, length);
  tk->last_token = type;
  rb_yield_values(3, token_type_to_symbol(type), INT2NUM(tk->scan.mb_cursor), INT2NUM(tk->scan.mb_cursor + mb_length));
}

static void tokenizer_callback(struct tokenizer_t *tk, enum token_type type, long unsigned int length)
{
  long unsigned int mb_length = tokenizer_mblength(tk, length);
  if(tk->f_callback)
    tk->f_callback(tk, type, length, tk->callback_data);
  tk->scan.cursor += length;
  tk->scan.mb_cursor += mb_length;
}

static VALUE tokenizer_initialize_method(VALUE self)
{
  struct tokenizer_t *tk = NULL;

  Tokenizer_Get_Struct(self, tk);
  DBG_PRINT("tk=%p initialize", tk);

  tokenizer_init(tk);
  tk->f_callback = tokenizer_yield_tag;

  return Qnil;
}

static inline int eos(struct scan_t *scan)
{
  return scan->cursor >= scan->length;
}

static inline long unsigned int length_remaining(struct scan_t *scan)
{
  return scan->length - scan->cursor;
}

static inline void push_context(struct tokenizer_t *tk, enum tokenizer_context ctx)
{
  tk->context[++tk->current_context] = ctx;
}

static inline void pop_context(struct tokenizer_t *tk)
{
  tk->context[tk->current_context--] = TOKENIZER_NONE;
}

static int is_text(struct scan_t *scan, long unsigned int *length)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(scan->string[i] == '<')
      break;
  }
  return *length != 0;
}

static inline int is_comment_start(struct scan_t *scan)
{
  return (length_remaining(scan) >= 4) &&
    !strncmp((const char *)&scan->string[scan->cursor], "<!--", 4);
}

static inline int is_doctype(struct scan_t *scan)
{
  return (length_remaining(scan) >= 9) &&
    !strncasecmp((const char *)&scan->string[scan->cursor], "<!DOCTYPE", 9);
}

static inline int is_cdata_start(struct scan_t *scan)
{
  return (length_remaining(scan) >= 9) &&
    !strncasecmp((const char *)&scan->string[scan->cursor], "<![CDATA[", 9);
}

static inline int is_char(struct scan_t *scan, const char c)
{
  return (length_remaining(scan) >= 1) && (scan->string[scan->cursor] == c);
}

static inline int is_alnum(const char c)
{
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
}

static int is_tag_start(struct scan_t *scan, long unsigned int *length,
  int *closing_tag, const char **tag_name, long unsigned int *tag_name_length)
{
  long unsigned int i, start;

  if(scan->string[scan->cursor] != '<')
    return 0;

  *length = 1;

  if(scan->string[scan->cursor+1] == '/') {
    *closing_tag = 1;
    (*length)++;
  } else {
    *closing_tag = 0;
  }

  *tag_name = &scan->string[scan->cursor + (*length)];
  start = *length;
  for(i = scan->cursor + (*length);i < scan->length; i++, (*length)++) {
    if(!is_alnum(scan->string[i]) && scan->string[i] != ':')
      break;
  }

  *tag_name_length = *length - start;
  return 1;
}

static int is_tag_name(struct scan_t *scan, const char **tag_name, unsigned long int *tag_name_length)
{
  long unsigned int i;

  *tag_name_length = 0;
  *tag_name = &scan->string[scan->cursor];
  for(i = scan->cursor;i < scan->length; i++, (*tag_name_length)++) {
    if(scan->string[i] == ' ' || scan->string[i] == '\t' ||
        scan->string[i] == '\r' || scan->string[i] == '\n' ||
        scan->string[i] == '>' || scan->string[i] == '/')
      break;
  }

  return *tag_name_length != 0;
}

static int is_whitespace(struct scan_t *scan, unsigned long int *length)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(scan->string[i] != ' ' && scan->string[i] != '\t' &&
        scan->string[i] != '\r' && scan->string[i] != '\n')
      break;
  }
  return *length != 0;
}

static int is_attribute_name(struct scan_t *scan, unsigned long int *length)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(!is_alnum(scan->string[i]) && scan->string[i] != ':' &&
        scan->string[i] != '-' && scan->string[i] != '_' &&
        scan->string[i] != '.')
      break;
  }
  return *length != 0;
}

static int is_unquoted_value(struct scan_t *scan, unsigned long int *length)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(scan->string[i] == ' ' || scan->string[i] == '\r' ||
        scan->string[i] == '\n' || scan->string[i] == '\t' ||
        scan->string[i] == '>')
      break;
  }
  return *length != 0;
}

static int is_attribute_string(struct scan_t *scan, unsigned long int *length, const char attribute_value_start)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(scan->string[i] == attribute_value_start)
      break;
  }
  return *length != 0;
}

static int is_comment_end(struct scan_t *scan, unsigned long int *length, const char **end)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(i < (scan->length - 2) && scan->string[i] == '-' && scan->string[i+1] == '-' &&
        scan->string[i+2] == '>') {
      *end = &scan->string[i];
      break;
    }
  }
  return *length != 0;
}

static int is_cdata_end(struct scan_t *scan, unsigned long int *length, const char **end)
{
  long unsigned int i;

  *length = 0;
  for(i = scan->cursor;i < scan->length; i++, (*length)++) {
    if(i < (scan->length-2) && scan->string[i] == ']' && scan->string[i+1] == ']' &&
        scan->string[i+2] == '>') {
      *end = &scan->string[i];
      break;
    }
  }
  return *length != 0;
}

static int scan_html(struct tokenizer_t *tk)
{
  long unsigned int length = 0;

  if(is_char(&tk->scan, '<')) {
    push_context(tk, TOKENIZER_OPEN_TAG);
    return 1;
  }
  else if(is_text(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_TEXT, length);
    return 1;
  }
  return 0;
}

static int scan_open_tag(struct tokenizer_t *tk)
{
  unsigned long int length = 0;

  if(is_comment_start(&tk->scan)) {
    tokenizer_callback(tk, TOKEN_COMMENT_START, 4);
    pop_context(tk); // back to html
    push_context(tk, TOKENIZER_COMMENT);
    return 1;
  }
  else if(is_doctype(&tk->scan)) {
    tokenizer_callback(tk, TOKEN_TAG_START, 1);
    tokenizer_callback(tk, TOKEN_TAG_NAME, 8);
    push_context(tk, TOKENIZER_TAG_NAME);
    return 1;
  }
  else if(is_cdata_start(&tk->scan)) {
    tokenizer_callback(tk, TOKEN_CDATA_START, 9);
    pop_context(tk); // back to html
    push_context(tk, TOKENIZER_CDATA);
    return 1;
  }
  else if(is_char(&tk->scan, '<')) {
    tokenizer_callback(tk, TOKEN_TAG_START, 1);
    push_context(tk, TOKENIZER_SOLIDUS_OR_TAG_NAME);
    return 1;
  }
  else if(is_whitespace(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_WHITESPACE, length);
    return 1;
  }
  else if(is_attribute_name(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_NAME, length);
    push_context(tk, TOKENIZER_ATTRIBUTE_NAME);
    return 1;
  }
  else if(is_char(&tk->scan, '\'') || is_char(&tk->scan, '"')) {
    push_context(tk, TOKENIZER_ATTRIBUTE_VALUE);
    return 1;
  }
  else if(is_char(&tk->scan, '=')) {
    tokenizer_callback(tk, TOKEN_EQUAL, 1);
    push_context(tk, TOKENIZER_ATTRIBUTE_VALUE);
    return 1;
  }
  else if(is_char(&tk->scan, '/')) {
    tokenizer_callback(tk, TOKEN_SOLIDUS, 1);
    return 1;
  }
  else if(is_char(&tk->scan, '>')) {
    tokenizer_callback(tk, TOKEN_TAG_END, 1);
    pop_context(tk); // pop tag context

    if(tk->current_tag && !tk->is_closing_tag) {
      if(!strcasecmp("title", tk->current_tag) ||
          !strcasecmp("textarea", tk->current_tag)) {
        push_context(tk, TOKENIZER_RCDATA);
        return 1;
      }
      else if(!strcasecmp("style", tk->current_tag) ||
          !strcasecmp("xmp", tk->current_tag) || !strcasecmp("iframe", tk->current_tag) ||
          !strcasecmp("noembed", tk->current_tag) || !strcasecmp("noframes", tk->current_tag) ||
          !strcasecmp("listing", tk->current_tag)) {
        push_context(tk, TOKENIZER_RAWTEXT);
        return 1;
      }
      else if(!strcasecmp("script", tk->current_tag)) {
        push_context(tk, TOKENIZER_SCRIPT_DATA);
        return 1;
      }
      else if(!strcasecmp("plaintext", tk->current_tag)) {
        push_context(tk, TOKENIZER_PLAINTEXT);
        return 1;
      }
    }
    return 1;
  }
  return 0;
}

static int scan_solidus_or_tag_name(struct tokenizer_t *tk)
{
  if(tk->current_tag)
    tk->current_tag[0] = '\0';

  if(is_char(&tk->scan, '/')) {
    tk->is_closing_tag = 1;
    tokenizer_callback(tk, TOKEN_SOLIDUS, 1);
  }
  else {
    tk->is_closing_tag = 0;
  }

  pop_context(tk);
  push_context(tk, TOKENIZER_TAG_NAME);
  return 1;
}

static int scan_tag_name(struct tokenizer_t *tk)
{
  unsigned long int length = 0, tag_name_length = 0;
  const char *tag_name = NULL;
  void *old;

  if(is_tag_name(&tk->scan, &tag_name, &tag_name_length)) {
    length = (tk->current_tag ? strlen(tk->current_tag) : 0);
    old = tk->current_tag;
    REALLOC_N(tk->current_tag, char, length + tag_name_length + 1);
    DBG_PRINT("tk=%p realloc(tk->current_tag) %p -> %p length=%lu", tk, old,
      tk->current_tag,  length + tag_name_length + 1);
    tk->current_tag[length] = 0;

    strncat(tk->current_tag, tag_name, tag_name_length);

    tokenizer_callback(tk, TOKEN_TAG_NAME, tag_name_length);
    return 1;
  }

  pop_context(tk); // back to open_tag
  return 1;
}

static int scan_attribute_name(struct tokenizer_t *tk)
{
  unsigned long int length = 0;

  if(is_attribute_name(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_NAME, length);
    return 1;
  }

  pop_context(tk); // back to open tag
  return 1;
}

static int scan_attribute_value(struct tokenizer_t *tk)
{
  unsigned long int length = 0;

  if(is_whitespace(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_WHITESPACE, length);
    return 1;
  }
  else if(is_char(&tk->scan, '\'') || is_char(&tk->scan, '"')) {
    tk->attribute_value_start = tk->scan.string[tk->scan.cursor];
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_QUOTED_VALUE_START, 1);
    pop_context(tk); // back to open tag
    push_context(tk, TOKENIZER_ATTRIBUTE_QUOTED);
    return 1;
  }

  pop_context(tk); // back to open tag
  push_context(tk, TOKENIZER_ATTRIBUTE_UNQUOTED);
  return 1;
}

static int scan_attribute_unquoted(struct tokenizer_t *tk)
{
  unsigned long int length = 0;

  if(is_unquoted_value(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_UNQUOTED_VALUE, length);
    return 1;
  }

  pop_context(tk); // back to open tag
  return 1;
}

static int scan_attribute_quoted(struct tokenizer_t *tk)
{
  unsigned long int length = 0;

  if(is_char(&tk->scan, tk->attribute_value_start)) {
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_QUOTED_VALUE_END, 1);
    pop_context(tk); // back to open tag
    return 1;
  }
  else if(is_attribute_string(&tk->scan, &length, tk->attribute_value_start)) {
    tokenizer_callback(tk, TOKEN_ATTRIBUTE_QUOTED_VALUE, length);
    return 1;
  }
  return 0;
}

static int scan_comment(struct tokenizer_t *tk)
{
  unsigned long int length = 0;
  const char *comment_end = NULL;

  if(is_comment_end(&tk->scan, &length, &comment_end)) {
    tokenizer_callback(tk, TOKEN_TEXT, length);
    if(comment_end) {
      tokenizer_callback(tk, TOKEN_COMMENT_END, 3);
      pop_context(tk); // back to document
    }
    return 1;
  }
  else {
    tokenizer_callback(tk, TOKEN_TEXT, length_remaining(&tk->scan));
    return 1;
  }
  return 0;
}

static int scan_cdata(struct tokenizer_t *tk)
{
  unsigned long int length = 0;
  const char *cdata_end = NULL;

  if(is_cdata_end(&tk->scan, &length, &cdata_end)) {
    tokenizer_callback(tk, TOKEN_TEXT, length);
    if(cdata_end) {
      tokenizer_callback(tk, TOKEN_CDATA_END, 3);
      pop_context(tk); // back to document
    }
    return 1;
  }
  else {
    tokenizer_callback(tk, TOKEN_TEXT, length_remaining(&tk->scan));
    return 1;
  }
  return 0;
}

static int scan_rawtext(struct tokenizer_t *tk)
{
  long unsigned int length = 0, tag_name_length = 0;
  const char *tag_name = NULL;
  int closing_tag = 0;

  if(is_tag_start(&tk->scan, &length, &closing_tag, &tag_name, &tag_name_length)) {
    if(closing_tag && tk->current_tag && !strncasecmp((const char *)tag_name, tk->current_tag, tag_name_length)) {
      pop_context(tk);
    } else {
      tokenizer_callback(tk, TOKEN_TEXT, length);
    }
    return 1;
  }
  else if(is_text(&tk->scan, &length)) {
    tokenizer_callback(tk, TOKEN_TEXT, length);
    return 1;
  }
  else {
    tokenizer_callback(tk, TOKEN_TEXT, length_remaining(&tk->scan));
    return 1;
  }
  return 0;
}

static int scan_plaintext(struct tokenizer_t *tk)
{
  tokenizer_callback(tk, TOKEN_TEXT, length_remaining(&tk->scan));
  return 1;
}

static int scan_once(struct tokenizer_t *tk)
{
  switch(tk->context[tk->current_context]) {
  case TOKENIZER_NONE:
    break;
  case TOKENIZER_HTML:
    return scan_html(tk);
  case TOKENIZER_OPEN_TAG:
    return scan_open_tag(tk);
  case TOKENIZER_SOLIDUS_OR_TAG_NAME:
    return scan_solidus_or_tag_name(tk);
  case TOKENIZER_TAG_NAME:
    return scan_tag_name(tk);
  case TOKENIZER_COMMENT:
    return scan_comment(tk);
  case TOKENIZER_CDATA:
    return scan_cdata(tk);
  case TOKENIZER_RCDATA:
  case TOKENIZER_RAWTEXT:
  case TOKENIZER_SCRIPT_DATA:
    /* we don't consume character references so all
      of these states are effectively the same */
    return scan_rawtext(tk);
  case TOKENIZER_PLAINTEXT:
    return scan_plaintext(tk);
  case TOKENIZER_ATTRIBUTE_NAME:
    return scan_attribute_name(tk);
  case TOKENIZER_ATTRIBUTE_VALUE:
    return scan_attribute_value(tk);
  case TOKENIZER_ATTRIBUTE_UNQUOTED:
    return scan_attribute_unquoted(tk);
  case TOKENIZER_ATTRIBUTE_QUOTED:
    return scan_attribute_quoted(tk);
  }
  return 0;
}

void tokenizer_scan_all(struct tokenizer_t *tk)
{
  while(!eos(&tk->scan) && scan_once(tk)) {}
  if(!eos(&tk->scan)) {
    tokenizer_callback(tk, TOKEN_MALFORMED, length_remaining(&tk->scan));
  }
  return;
}

void tokenizer_set_scan_string(struct tokenizer_t *tk, const char *string, long unsigned int length)
{
  const char *old = tk->scan.string;
  REALLOC_N(tk->scan.string, char, string ? length + 1 : 0);
  DBG_PRINT("tk=%p realloc(tk->scan.string) %p -> %p length=%lu", tk, old,
    tk->scan.string, length + 1);
  if(string && length > 0) {
    strncpy(tk->scan.string, string, length);
    tk->scan.string[length] = 0;
  }
  tk->scan.length = length;
  return;
}

void tokenizer_free_scan_string(struct tokenizer_t *tk)
{
  tokenizer_set_scan_string(tk, NULL, 0);
  return;
}

static VALUE tokenizer_tokenize_method(VALUE self, VALUE source)
{
  struct tokenizer_t *tk = NULL;
  char *c_source;

  if(NIL_P(source))
    return Qnil;

  Check_Type(source, T_STRING);
  Tokenizer_Get_Struct(self, tk);

  c_source = StringValueCStr(source);
  tk->scan.cursor = 0;
  tokenizer_set_scan_string(tk, c_source, strlen(c_source));
  tk->scan.enc_index = rb_enc_get_index(source);
  tk->scan.mb_cursor = 0;

  tokenizer_scan_all(tk);

  tokenizer_free_scan_string(tk);

  return Qtrue;
}

void Init_html_tokenizer_tokenizer(VALUE mHtmlTokenizer)
{
  cTokenizer = rb_define_class_under(mHtmlTokenizer, "Tokenizer", rb_cObject);
  rb_define_alloc_func(cTokenizer, tokenizer_allocate);
  rb_define_method(cTokenizer, "initialize", tokenizer_initialize_method, 0);
  rb_define_method(cTokenizer, "tokenize", tokenizer_tokenize_method, 1);
}
