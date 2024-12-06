#include <ruby.h>
#include <ruby/encoding.h>
#include "html_tokenizer.h"
#include "parser.h"

static VALUE cParser = Qnil;

static void parser_mark(void *ptr)
{}

static void parser_free(void *ptr)
{
  struct parser_t *parser = ptr;
  size_t i;

  if(parser) {
    tokenizer_free_members(&parser->tk);
    if(parser->doc.data) {
      DBG_PRINT("parser=%p xfree(parser->doc.data) %p", parser, parser->doc.data);
      xfree(parser->doc.data);
      parser->doc.data = NULL;
    }
    if(parser->errors_count && parser->errors) {
      for(i=0; i<parser->errors_count; i++) {
        if(!parser->errors[i].message)
          continue;
        DBG_PRINT("parser=%p xfree(parser->errors.messages[%u]) %p", parser, i, parser->errors[i].message);
        xfree(parser->errors[i].message);
        parser->errors[i].message = NULL;
      }
      DBG_PRINT("parser=%p xfree(parser->errors.messages) %p", parser, parser->errors);
      xfree(parser->errors);
      parser->errors = NULL;
      parser->errors_count = 0;
    }
    DBG_PRINT("parser=%p xfree(parser)", parser);
    xfree(parser);
  }
}

static size_t parser_memsize(const void *ptr)
{
  return ptr ? sizeof(struct parser_t) : 0;
}

const rb_data_type_t ht_parser_data_type = {
  "ht_parser_data_type",
  { parser_mark, parser_free, parser_memsize, },
#if defined(RUBY_TYPED_FREE_IMMEDIATELY)
  NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static VALUE parser_allocate(VALUE klass)
{
  VALUE obj;
  struct parser_t *parser = NULL;

  obj = TypedData_Make_Struct(klass, struct parser_t, &ht_parser_data_type, parser);
  DBG_PRINT("parser=%p allocate", parser);

  return obj;
}

static inline void parser_append_ref(struct token_reference_t *dest, struct token_reference_t *src)
{
  if(dest->type == TOKEN_NONE || dest->type != src->type || (dest->start + dest->length) != src->start) {
    dest->type = src->type;
    dest->start = src->start;
    dest->mb_start = src->mb_start;
    dest->length = src->length;
    dest->line_number = src->line_number;
    dest->column_number = src->column_number;
  }
  else {
    dest->type = src->type;
    dest->length += src->length;
  }
}

static void parser_add_error(struct parser_t *parser, const char *message)
{
  REALLOC_N(parser->errors, struct parser_document_error_t, parser->errors_count + 1);
  parser->errors[parser->errors_count].message = strdup(message);
  parser->errors[parser->errors_count].pos = parser->tk.scan.cursor;
  parser->errors[parser->errors_count].mb_pos = parser->tk.scan.mb_cursor;
  parser->errors[parser->errors_count].line_number = parser->doc.line_number;
  parser->errors[parser->errors_count].column_number = parser->doc.column_number;
  parser->errors_count += 1;
  return;
}

static int parse_none(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_TAG_START) {
    parser->tag.self_closing = 0;
    parser->context = PARSER_SOLIDUS_OR_TAG_NAME;
    parser->tag.name.type = TOKEN_NONE;
  }
  else if(ref->type == TOKEN_COMMENT_START) {
    parser->context = PARSER_COMMENT;
    parser->comment.text.type = TOKEN_NONE;
  }
  else if(ref->type == TOKEN_CDATA_START) {
    parser->context = PARSER_CDATA;
    parser->cdata.text.type = TOKEN_NONE;
  }
  PARSE_DONE;
}

static int parse_rawtext(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_TEXT) {
    parser_append_ref(&parser->rawtext.text, ref);
  }
  else {
    parser->context = PARSER_NONE;
    parse_none(parser, ref);
  }
  PARSE_DONE;
}

static int parse_comment(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_COMMENT_END) {
    parser->context = PARSER_NONE;
  }
  else if(ref->type == TOKEN_TEXT) {
    parser_append_ref(&parser->comment.text, ref);
  }
  PARSE_DONE;
}

static int parse_cdata(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_CDATA_END) {
    parser->context = PARSER_NONE;
  }
  else if(ref->type == TOKEN_TEXT) {
    parser_append_ref(&parser->cdata.text, ref);
  }
  PARSE_DONE;
}

static int parse_solidus_or_tag_name(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_SOLIDUS) {
    // ignore solidus before tag name
    parser->context = PARSER_TAG_NAME;
  }
  else if(ref->type == TOKEN_TAG_NAME) {
    parser->context = PARSER_TAG_NAME;
    PARSE_AGAIN;
  }
  else {
    parser_add_error(parser, "expected '/' or tag name");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  PARSE_DONE;
}

static int parse_tag_name(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_TAG_NAME) {
    parser_append_ref(&parser->tag.name, ref);
  }
  else if(ref->type == TOKEN_WHITESPACE) {
    parser->context = PARSER_TAG;
  }
  else if(ref->type == TOKEN_TAG_END) {
    parser->context = PARSER_NONE;
  }
  else if(ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else {
    // not reachable
    rb_raise(rb_eArgError, "expected whitespace, '/' or '>' after tag name");
  }
  PARSE_DONE;
}

static int parse_tag(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_TAG_END) {
    parser->context = PARSER_NONE;
  }
  else if(ref->type == TOKEN_WHITESPACE) {
    // ignore whitespaces
  }
  else if(ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG_END;
  }
  else if(ref->type == TOKEN_ATTRIBUTE_NAME) {
    parser->context = PARSER_ATTRIBUTE_NAME;
    parser->attribute.name.type = TOKEN_NONE;
    parser->attribute.value.type = TOKEN_NONE;
    parser->attribute.is_quoted = 0;
    PARSE_AGAIN;
  }
  else if(ref->type == TOKEN_ATTRIBUTE_QUOTED_VALUE_START) {
    parser->context = PARSER_ATTRIBUTE_QUOTED_VALUE;
    parser->attribute.name.type = TOKEN_NONE;
    parser->attribute.value.type = TOKEN_NONE;
    parser->attribute.is_quoted = 1;
  }
  else {
    // unexpected
    parser_add_error(parser, "expected whitespace, '>', attribute name or value");
  }
  PARSE_DONE;
}

static int parse_tag_end(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_TAG_END) {
    parser->tag.self_closing = 1;
    parser->context = PARSER_NONE;
  }
  else {
    parser_add_error(parser, "expected '>' after '/'");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  PARSE_DONE;
}

static int parse_attribute_name(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_ATTRIBUTE_NAME) {
    parser_append_ref(&parser->attribute.name, ref);
  }
  else if(ref->type == TOKEN_TAG_END || ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else if(ref->type == TOKEN_WHITESPACE) {
    parser->context = PARSER_ATTRIBUTE_WHITESPACE_OR_EQUAL;
    PARSE_AGAIN;
  }
  else if(ref->type == TOKEN_EQUAL) {
    parser->context = PARSER_ATTRIBUTE_WHITESPACE_OR_VALUE;
  }
  else {
    parser_add_error(parser, "expected whitespace, '>' or '=' after attribute name");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  PARSE_DONE;
}

static int parse_attribute_whitespace_or_equal(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_WHITESPACE) {
    // swallow whitespace after attribute name
  }
  else if(ref->type == TOKEN_TAG_END || ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else if(ref->type == TOKEN_EQUAL) {
    parser->context = PARSER_ATTRIBUTE_WHITESPACE_OR_VALUE;
  }
  else if(ref->type == TOKEN_ATTRIBUTE_NAME) {
    // start new attribute after whitespace
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else if(ref->type == TOKEN_ATTRIBUTE_QUOTED_VALUE_START) {
    // start quoted value after whitespace
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else {
    parser_add_error(parser, "expected '/', '>', \", ' or '=' after attribute name");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }

  PARSE_DONE;
}

static int parse_attribute_whitespace_or_value(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_WHITESPACE) {
    // swallow whitespace after equal sign
  }
  else if(ref->type == TOKEN_ATTRIBUTE_QUOTED_VALUE_START) {
    parser->context = PARSER_ATTRIBUTE_QUOTED_VALUE;
    parser->attribute.is_quoted = 1;
  }
  else if(ref->type == TOKEN_ATTRIBUTE_UNQUOTED_VALUE) {
    parser->context = PARSER_ATTRIBUTE_UNQUOTED_VALUE;
    PARSE_AGAIN;
  }
  else {
    parser_add_error(parser, "expected attribute value after '='");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }

  PARSE_DONE;
}

static int parse_attribute_quoted_value(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_ATTRIBUTE_QUOTED_VALUE) {
    parser_append_ref(&parser->attribute.value, ref);
  }
  else if(ref->type == TOKEN_ATTRIBUTE_QUOTED_VALUE_END) {
    parser->context = PARSER_SPACE_AFTER_ATTRIBUTE;
  }
  else {
    // not reachable
    rb_raise(rb_eArgError, "expected end-quote after quoted value");
  }

  PARSE_DONE;
}

static int parse_space_after_attribute(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_WHITESPACE) {
    parser->context = PARSER_TAG;
  }
  else if(ref->type == TOKEN_TAG_END || ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else {
    parser_add_error(parser, "expected space after attribute value");
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }

  PARSE_DONE;
}

static int parse_attribute_unquoted_value(struct parser_t *parser, struct token_reference_t *ref)
{
  if(ref->type == TOKEN_ATTRIBUTE_UNQUOTED_VALUE) {
    parser_append_ref(&parser->attribute.value, ref);
  }
  else if(ref->type == TOKEN_WHITESPACE) {
    parser->context = PARSER_TAG;
  }
  else if(ref->type == TOKEN_TAG_END || ref->type == TOKEN_SOLIDUS) {
    parser->context = PARSER_TAG;
    PARSE_AGAIN;
  }
  else {
    // not reachable
    rb_raise(rb_eArgError, "expected space or end-of-tag after unquoted value");
  }

  PARSE_DONE;
}

static inline int rawtext_context(struct parser_t *parser)
{
  enum tokenizer_context ctx = parser->tk.context[parser->tk.current_context];
  return (ctx == TOKENIZER_RCDATA || ctx == TOKENIZER_RAWTEXT ||
      ctx == TOKENIZER_SCRIPT_DATA || ctx == TOKENIZER_PLAINTEXT);
}

static void parser_adjust_line_number(struct parser_t *parser, long unsigned int start, long unsigned int length)
{
  rb_encoding *enc = rb_enc_from_index(parser->doc.enc_index);
  long unsigned int i;
  const char *buf, *nextlf;

  for(i = 0; i < length;) {
    buf = &parser->doc.data[start + i];
    nextlf = memchr(buf, '\n', length - i);
    if(nextlf) {
      parser->doc.column_number = 0;
      parser->doc.line_number += 1;
      i += (nextlf - buf) + 1;
    }
    else {
      parser->doc.column_number += rb_enc_strlen(buf, buf + length - i, enc);
      break;
    }
  }

  return;
}

static void parser_tokenize_callback(struct tokenizer_t *tk, enum token_type type, unsigned long int length, void *data)
{
  struct parser_t *parser = (struct parser_t *)data;
  struct token_reference_t ref = {
    .type = type,
    .start = tk->scan.cursor,
    .mb_start = tk->scan.mb_cursor,
    .length = length,
    .line_number = parser->doc.line_number,
    .column_number = parser->doc.column_number,
  };
  int parse_again = 1;
  long unsigned int mb_strlen;
  rb_encoding *enc;

  while(parse_again) {
    switch(parser->context)
    {
    case PARSER_NONE:
      if(rawtext_context(parser))
        parse_again = parse_rawtext(parser, &ref);
      else
        parse_again = parse_none(parser, &ref);
      break;
    case PARSER_SOLIDUS_OR_TAG_NAME:
      parse_again = parse_solidus_or_tag_name(parser, &ref);
      break;
    case PARSER_TAG_NAME:
      parse_again = parse_tag_name(parser, &ref);
      break;
    case PARSER_TAG:
      parse_again = parse_tag(parser, &ref);
      break;
    case PARSER_ATTRIBUTE_NAME:
      parse_again = parse_attribute_name(parser, &ref);
      break;
    case PARSER_ATTRIBUTE_WHITESPACE_OR_EQUAL:
      parse_again = parse_attribute_whitespace_or_equal(parser, &ref);
      break;
    case PARSER_ATTRIBUTE_WHITESPACE_OR_VALUE:
      parse_again = parse_attribute_whitespace_or_value(parser, &ref);
      break;
    case PARSER_ATTRIBUTE_QUOTED_VALUE:
      parse_again = parse_attribute_quoted_value(parser, &ref);
      break;
    case PARSER_SPACE_AFTER_ATTRIBUTE:
      parse_again = parse_space_after_attribute(parser, &ref);
      break;
    case PARSER_ATTRIBUTE_UNQUOTED_VALUE:
      parse_again = parse_attribute_unquoted_value(parser, &ref);
      break;
    case PARSER_TAG_END:
      parse_again = parse_tag_end(parser, &ref);
      break;
    case PARSER_CDATA:
      parse_again = parse_cdata(parser, &ref);
      break;
    case PARSER_COMMENT:
      parse_again = parse_comment(parser, &ref);
      break;
    }
  }

  if(rb_block_given_p()) {
    enc = rb_enc_from_index(parser->doc.enc_index);
    mb_strlen = rb_enc_strlen(parser->doc.data + ref.start, parser->doc.data + ref.start + ref.length, enc);
    rb_yield_values(5, token_type_to_symbol(type),
      INT2NUM(ref.mb_start), INT2NUM(ref.mb_start + mb_strlen),
      INT2NUM(ref.line_number), INT2NUM(ref.column_number));
  }

  parser_adjust_line_number(parser, ref.start, ref.length);

  return;
}

static VALUE parser_initialize_method(VALUE self)
{
  struct parser_t *parser = NULL;

  Parser_Get_Struct(self, parser);
  DBG_PRINT("parser=%p initialize", parser);

  memset(parser, 0, sizeof(struct parser_t));

  parser->context = PARSER_NONE;

  tokenizer_init(&parser->tk);
  parser->tk.callback_data = parser;
  parser->tk.f_callback = parser_tokenize_callback;

  parser->doc.length = 0;
  parser->doc.data = NULL;
  parser->doc.enc_index = 0;
  parser->doc.mb_length = 0;

  parser->doc.line_number = 1;
  parser->doc.column_number = 0;

  parser->errors_count = 0;
  parser->errors = NULL;

  return Qnil;
}

static int parser_document_append(struct parser_t *parser, const char *string, unsigned long int length)
{
  void *old = parser->doc.data;
  unsigned long int mb_length;
  char *buf;
  rb_encoding *enc = rb_enc_from_index(parser->doc.enc_index);
  REALLOC_N(parser->doc.data, char, parser->doc.length + length + 1);
  DBG_PRINT("parser=%p realloc(parser->doc.data) %p -> %p length=%lu", parser, old,
    parser->doc.data, parser->doc.length + length + 1);
  buf = parser->doc.data + parser->doc.length;
  strcpy(buf, string);
  mb_length = rb_enc_strlen(buf, buf + length, enc);
  parser->doc.length += length;
  parser->doc.mb_length += mb_length;
  return 1;
}

static VALUE parser_append_data(VALUE self, VALUE source, int is_placeholder)
{
  struct parser_t *parser = NULL;
  char *string = NULL;
  long unsigned int length = 0, cursor = 0, mb_cursor = 0;

  if(NIL_P(source))
    return Qnil;

  Check_Type(source, T_STRING);
  Parser_Get_Struct(self, parser);

  string = StringValueCStr(source);
  length = strlen(string);

  cursor = parser->doc.length;
  mb_cursor = parser->doc.mb_length;

  if(parser->doc.data == NULL) {
    parser->doc.enc_index = rb_enc_get_index(source);
  }
  else if(parser->doc.enc_index != rb_enc_get_index(source)) {
    rb_raise(rb_eArgError, "cannot append %s string to %s document",
      rb_enc_name(rb_enc_get(source)), rb_enc_name(rb_enc_from_index(parser->doc.enc_index)));
  }

  if(!parser_document_append(parser, string, length)) {
    // error
    return Qnil;
  }

  if(is_placeholder) {
    parser_adjust_line_number(parser, cursor, length);
  }
  else {
    parser->tk.scan.cursor = cursor;
    tokenizer_set_scan_string(&parser->tk, parser->doc.data, parser->doc.length);
    parser->tk.scan.enc_index = parser->doc.enc_index;
    parser->tk.scan.mb_cursor = mb_cursor;

    tokenizer_scan_all(&parser->tk);
    tokenizer_free_scan_string(&parser->tk);
  }

  return Qtrue;
}

static VALUE parser_parse_method(VALUE self, VALUE source)
{
  return parser_append_data(self, source, 0);
}

static VALUE parser_append_placeholder_method(VALUE self, VALUE source)
{
  return parser_append_data(self, source, 1);
}

static VALUE parser_document_method(VALUE self)
{
  struct parser_t *parser = NULL;
  rb_encoding *enc;
  Parser_Get_Struct(self, parser);
  if(!parser->doc.data)
    return Qnil;
  enc = rb_enc_from_index(parser->doc.enc_index);
  return rb_enc_str_new(parser->doc.data, parser->doc.length, enc);
}

static VALUE parser_document_length_method(VALUE self)
{
  struct parser_t *parser = NULL;
  rb_encoding *enc;
  const char *buf;

  Parser_Get_Struct(self, parser);

  if(parser->doc.data == NULL) {
    return ULONG2NUM(0);
  }
  else {
    buf = parser->doc.data;
    enc = rb_enc_from_index(parser->doc.enc_index);
    return ULONG2NUM(rb_enc_strlen(buf, buf + parser->doc.length, enc));
  }
}

static VALUE parser_context_method(VALUE self)
{
  struct parser_t *parser = NULL;

  Parser_Get_Struct(self, parser);

  switch(parser->context) {
  case PARSER_NONE:
    return rawtext_context(parser) ? ID2SYM(rb_intern("rawtext")) : ID2SYM(rb_intern("none"));
  case PARSER_SOLIDUS_OR_TAG_NAME:
    return ID2SYM(rb_intern("solidus_or_tag_name"));
  case PARSER_TAG_NAME:
    return ID2SYM(rb_intern("tag_name"));
  case PARSER_TAG:
    return ID2SYM(rb_intern("tag"));
  case PARSER_ATTRIBUTE_NAME:
    return ID2SYM(rb_intern("attribute_name"));
  case PARSER_ATTRIBUTE_WHITESPACE_OR_EQUAL:
    return ID2SYM(rb_intern("after_attribute_name"));
  case PARSER_ATTRIBUTE_WHITESPACE_OR_VALUE:
    return ID2SYM(rb_intern("after_equal"));
  case PARSER_ATTRIBUTE_QUOTED_VALUE:
    return ID2SYM(rb_intern("quoted_value"));
  case PARSER_SPACE_AFTER_ATTRIBUTE:
    return ID2SYM(rb_intern("space_after_attribute"));
  case PARSER_ATTRIBUTE_UNQUOTED_VALUE:
    return ID2SYM(rb_intern("unquoted_value"));
  case PARSER_TAG_END:
    return ID2SYM(rb_intern("tag_end"));
  case PARSER_COMMENT:
    return ID2SYM(rb_intern("comment"));
  case PARSER_CDATA:
    return ID2SYM(rb_intern("cdata"));
  }

  return Qnil;
}

static inline VALUE ref_to_str(struct parser_t *parser, struct token_reference_t *ref)
{
  rb_encoding *enc = rb_enc_from_index(parser->doc.enc_index);
  if(ref->type == TOKEN_NONE || parser->doc.data == NULL)
    return Qnil;
  return rb_enc_str_new(parser->doc.data+ref->start, ref->length, enc);
}

static VALUE parser_tag_name_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->tag.name);
}

static VALUE parser_closing_tag_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return parser->tk.is_closing_tag ? Qtrue : Qfalse;
}

static VALUE parser_self_closing_tag_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return parser->tag.self_closing ? Qtrue : Qfalse;
}

static VALUE parser_attribute_name_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->attribute.name);
}

static VALUE parser_attribute_value_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->attribute.value);
}

static VALUE parser_quote_character_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return parser->attribute.is_quoted ?
    rb_str_new(&parser->tk.attribute_value_start, 1) :
    Qnil;
}

static VALUE parser_attribute_is_quoted_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return parser->attribute.is_quoted ? Qtrue : Qfalse;
}

static VALUE parser_comment_text_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->comment.text);
}

static VALUE parser_cdata_text_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->cdata.text);
}

static VALUE parser_rawtext_text_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ref_to_str(parser, &parser->rawtext.text);
}

static VALUE parser_errors_count_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return INT2NUM(parser->errors_count);
}

static VALUE create_parser_error(struct parser_document_error_t *error)
{
  VALUE module = rb_const_get(rb_cObject, rb_intern("BetterHtml"));
  VALUE klass = rb_const_get(module, rb_intern("ParserError"));
  VALUE args[4] = {
    rb_str_new2(error->message),
    ULONG2NUM(error->mb_pos),
    ULONG2NUM(error->line_number),
    ULONG2NUM(error->column_number),
  };
  return rb_class_new_instance(4, args, klass);
}

static VALUE parser_errors_method(VALUE self)
{
  struct parser_t *parser = NULL;
  VALUE list;
  size_t i;
  Parser_Get_Struct(self, parser);

  list = rb_ary_new();
  for(i=0; i<parser->errors_count; i++) {
    if(parser->errors[i].message) {
      rb_ary_push(list, create_parser_error(&parser->errors[i]));
    }
  }

  return list;
}

static VALUE parser_line_number_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ULONG2NUM(parser->doc.line_number);
}

static VALUE parser_column_number_method(VALUE self)
{
  struct parser_t *parser = NULL;
  Parser_Get_Struct(self, parser);
  return ULONG2NUM(parser->doc.column_number);
}

void Init_html_tokenizer_parser(VALUE mHtmlTokenizer)
{
  cParser = rb_define_class_under(mHtmlTokenizer, "Parser", rb_cObject);
  rb_define_alloc_func(cParser, parser_allocate);
  rb_define_method(cParser, "initialize", parser_initialize_method, 0);
  rb_define_method(cParser, "document", parser_document_method, 0);
  rb_define_method(cParser, "document_length", parser_document_length_method, 0);
  rb_define_method(cParser, "line_number", parser_line_number_method, 0);
  rb_define_method(cParser, "column_number", parser_column_number_method, 0);
  rb_define_method(cParser, "parse", parser_parse_method, 1);
  rb_define_method(cParser, "append_placeholder", parser_append_placeholder_method, 1);
  rb_define_method(cParser, "context", parser_context_method, 0);
  rb_define_method(cParser, "tag_name", parser_tag_name_method, 0);
  rb_define_method(cParser, "closing_tag?", parser_closing_tag_method, 0);
  rb_define_method(cParser, "self_closing_tag?", parser_self_closing_tag_method, 0);
  rb_define_method(cParser, "attribute_name", parser_attribute_name_method, 0);
  rb_define_method(cParser, "attribute_value", parser_attribute_value_method, 0);
  rb_define_method(cParser, "quote_character", parser_quote_character_method, 0);
  rb_define_method(cParser, "attribute_quoted?", parser_attribute_is_quoted_method, 0);
  rb_define_method(cParser, "comment_text", parser_comment_text_method, 0);
  rb_define_method(cParser, "cdata_text", parser_cdata_text_method, 0);
  rb_define_method(cParser, "rawtext_text", parser_rawtext_text_method, 0);

  rb_define_method(cParser, "errors_count", parser_errors_count_method, 0);
  rb_define_method(cParser, "errors", parser_errors_method, 0);
}
