#include <nokogiri.h>

VALUE cNokogiriXmlSaxPushParser ;

static void
xml_sax_push_parser_free(void *data)
{
  xmlParserCtxtPtr ctx = data;
  if (ctx != NULL) {
    NOKOGIRI_SAX_TUPLE_DESTROY(ctx->userData);
    xmlFreeParserCtxt(ctx);
  }
}

static const rb_data_type_t xml_sax_push_parser_type = {
  .wrap_struct_name = "Nokogiri::XML::SAX::PushParser",
  .function = {
    .dfree = xml_sax_push_parser_free,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
allocate(VALUE klass)
{
  return TypedData_Wrap_Struct(klass, &xml_sax_push_parser_type, NULL);
}

xmlParserCtxtPtr
noko_xml_sax_push_parser_unwrap(VALUE rb_parser)
{
  xmlParserCtxtPtr c_parser;
  TypedData_Get_Struct(rb_parser, xmlParserCtxt, &xml_sax_push_parser_type, c_parser);
  return c_parser;
}

/*
 * call-seq:
 *  native_write(chunk, last_chunk)
 *
 * Write +chunk+ to PushParser. +last_chunk+ triggers the end_document handle
 */
static VALUE
native_write(VALUE self, VALUE _chunk, VALUE _last_chunk)
{
  xmlParserCtxtPtr ctx;
  const char *chunk  = NULL;
  int size            = 0;


  ctx = noko_xml_sax_push_parser_unwrap(self);

  if (Qnil != _chunk) {
    chunk = StringValuePtr(_chunk);
    size = (int)RSTRING_LEN(_chunk);
  }

  xmlSetStructuredErrorFunc(NULL, NULL);

  if (xmlParseChunk(ctx, chunk, size, Qtrue == _last_chunk ? 1 : 0)) {
    if (!(ctx->options & XML_PARSE_RECOVER)) {
      xmlErrorConstPtr e = xmlCtxtGetLastError(ctx);
      Nokogiri_error_raise(NULL, e);
    }
  }

  return self;
}

/*
 * call-seq:
 *  initialize_native(xml_sax, filename)
 *
 * Initialize the push parser with +xml_sax+ using +filename+
 */
static VALUE
initialize_native(VALUE self, VALUE _xml_sax, VALUE _filename)
{
  xmlSAXHandlerPtr sax;
  const char *filename = NULL;
  xmlParserCtxtPtr ctx;

  sax = noko_sax_handler_unwrap(_xml_sax);

  if (_filename != Qnil) { filename = StringValueCStr(_filename); }

  ctx = xmlCreatePushParserCtxt(
          sax,
          NULL,
          NULL,
          0,
          filename
        );
  if (ctx == NULL) {
    rb_raise(rb_eRuntimeError, "Could not create a parser context");
  }

  ctx->userData = NOKOGIRI_SAX_TUPLE_NEW(ctx, self);

  ctx->sax2 = 1;
  DATA_PTR(self) = ctx;
  return self;
}

static VALUE
get_options(VALUE self)
{
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  return INT2NUM(ctx->options);
}

static VALUE
set_options(VALUE self, VALUE options)
{
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  if (xmlCtxtUseOptions(ctx, (int)NUM2INT(options)) != 0) {
    rb_raise(rb_eRuntimeError, "Cannot set XML parser context options");
  }

  return Qnil;
}

/*
 * call-seq:
 *  replace_entities
 *
 * Should this parser replace entities?  &amp; will get converted to '&' if
 * set to true
 */
static VALUE
get_replace_entities(VALUE self)
{
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  if (0 == ctx->replaceEntities) {
    return Qfalse;
  } else {
    return Qtrue;
  }
}

/*
 * call-seq:
 *  replace_entities=(boolean)
 *
 * Should this parser replace entities?  &amp; will get converted to '&' if
 * set to true
 */
static VALUE
set_replace_entities(VALUE self, VALUE value)
{
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  if (Qfalse == value) {
    ctx->replaceEntities = 0;
  } else {
    ctx->replaceEntities = 1;
  }

  return value;
}

void
noko_init_xml_sax_push_parser(void)
{
  cNokogiriXmlSaxPushParser = rb_define_class_under(mNokogiriXmlSax, "PushParser", rb_cObject);

  rb_define_alloc_func(cNokogiriXmlSaxPushParser, allocate);

  rb_define_method(cNokogiriXmlSaxPushParser, "options", get_options, 0);
  rb_define_method(cNokogiriXmlSaxPushParser, "options=", set_options, 1);
  rb_define_method(cNokogiriXmlSaxPushParser, "replace_entities", get_replace_entities, 0);
  rb_define_method(cNokogiriXmlSaxPushParser, "replace_entities=", set_replace_entities, 1);

  rb_define_private_method(cNokogiriXmlSaxPushParser, "initialize_native", initialize_native, 2);
  rb_define_private_method(cNokogiriXmlSaxPushParser, "native_write", native_write, 2);
}
