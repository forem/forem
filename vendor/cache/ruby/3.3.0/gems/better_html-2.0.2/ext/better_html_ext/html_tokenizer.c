#include <ruby.h>
#include "tokenizer.h"
#include "parser.h"

static VALUE mHtmlTokenizer = Qnil;

void Init_better_html_ext()
{
  mHtmlTokenizer = rb_define_module("HtmlTokenizer");
  Init_html_tokenizer_tokenizer(mHtmlTokenizer);
  Init_html_tokenizer_parser(mHtmlTokenizer);
}
