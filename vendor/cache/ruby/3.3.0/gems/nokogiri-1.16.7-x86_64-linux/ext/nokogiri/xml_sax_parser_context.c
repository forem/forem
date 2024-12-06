#include <nokogiri.h>

VALUE cNokogiriXmlSaxParserContext ;

static ID id_read;

static void
xml_sax_parser_context_free(void *data)
{
  xmlParserCtxtPtr ctxt = data;
  ctxt->sax = NULL;
  xmlFreeParserCtxt(ctxt);
}

/*
 *  note that htmlParserCtxtPtr == xmlParserCtxtPtr and xmlFreeParserCtxt() == htmlFreeParserCtxt()
 *  so we use this type for both XML::SAX::ParserContext and HTML::SAX::ParserContext
 */
static const rb_data_type_t xml_sax_parser_context_type = {
  .wrap_struct_name = "Nokogiri::XML::SAX::ParserContext",
  .function = {
    .dfree = xml_sax_parser_context_free,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

xmlParserCtxtPtr
noko_xml_sax_parser_context_unwrap(VALUE rb_context)
{
  xmlParserCtxtPtr c_context;
  TypedData_Get_Struct(rb_context, xmlParserCtxt, &xml_sax_parser_context_type, c_context);
  return c_context;
}

VALUE
noko_xml_sax_parser_context_wrap(VALUE klass, xmlParserCtxtPtr c_context)
{
  return TypedData_Wrap_Struct(klass, &xml_sax_parser_context_type, c_context);
}


/*
 * call-seq:
 *  parse_io(io, encoding)
 *
 * Parse +io+ object with +encoding+
 */
static VALUE
parse_io(VALUE klass, VALUE io, VALUE encoding)
{
  xmlParserCtxtPtr ctxt;
  xmlCharEncoding enc = (xmlCharEncoding)NUM2INT(encoding);

  if (!rb_respond_to(io, id_read)) {
    rb_raise(rb_eTypeError, "argument expected to respond to :read");
  }

  ctxt = xmlCreateIOParserCtxt(NULL, NULL,
                               (xmlInputReadCallback)noko_io_read,
                               (xmlInputCloseCallback)noko_io_close,
                               (void *)io, enc);
  if (!ctxt) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

/*
 * call-seq:
 *  parse_file(filename)
 *
 * Parse file given +filename+
 */
static VALUE
parse_file(VALUE klass, VALUE filename)
{
  xmlParserCtxtPtr ctxt = xmlCreateFileParserCtxt(StringValueCStr(filename));

  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

/*
 * call-seq:
 *  parse_memory(data)
 *
 * Parse the XML stored in memory in +data+
 */
static VALUE
parse_memory(VALUE klass, VALUE data)
{
  xmlParserCtxtPtr ctxt;

  Check_Type(data, T_STRING);

  if (!(int)RSTRING_LEN(data)) {
    rb_raise(rb_eRuntimeError, "data cannot be empty");
  }

  ctxt = xmlCreateMemoryParserCtxt(StringValuePtr(data),
                                   (int)RSTRING_LEN(data));
  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

static VALUE
parse_doc(VALUE ctxt_val)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr)ctxt_val;
  xmlParseDocument(ctxt);
  return Qnil;
}

static VALUE
parse_doc_finalize(VALUE ctxt_val)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr)ctxt_val;

  if (NULL != ctxt->myDoc) {
    xmlFreeDoc(ctxt->myDoc);
  }

  NOKOGIRI_SAX_TUPLE_DESTROY(ctxt->userData);
  return Qnil;
}

/*
 * call-seq:
 *  parse_with(sax_handler)
 *
 * Use +sax_handler+ and parse the current document
 */
static VALUE
parse_with(VALUE self, VALUE sax_handler)
{
  xmlParserCtxtPtr ctxt;
  xmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(sax_handler, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  ctxt = noko_xml_sax_parser_context_unwrap(self);
  sax = noko_sax_handler_unwrap(sax_handler);

  ctxt->sax = sax;
  ctxt->userData = (void *)NOKOGIRI_SAX_TUPLE_NEW(ctxt, sax_handler);

  xmlSetStructuredErrorFunc(NULL, NULL);

  rb_ensure(parse_doc, (VALUE)ctxt, parse_doc_finalize, (VALUE)ctxt);

  return Qnil;
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
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);

  if (Qfalse == value) {
    ctxt->replaceEntities = 0;
  } else {
    ctxt->replaceEntities = 1;
  }

  return value;
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
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);

  if (0 == ctxt->replaceEntities) {
    return Qfalse;
  } else {
    return Qtrue;
  }
}

/*
 * call-seq: line
 *
 * Get the current line the parser context is processing.
 */
static VALUE
line(VALUE self)
{
  xmlParserInputPtr io;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->line);
  }

  return Qnil;
}

/*
 * call-seq: column
 *
 * Get the current column the parser context is processing.
 */
static VALUE
column(VALUE self)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);
  xmlParserInputPtr io;

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->col);
  }

  return Qnil;
}

/*
 * call-seq:
 *  recovery=(boolean)
 *
 * Should this parser recover from structural errors? It will not stop processing
 * file on structural errors if set to true
 */
static VALUE
set_recovery(VALUE self, VALUE value)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);

  if (value == Qfalse) {
    ctxt->recovery = 0;
  } else {
    ctxt->recovery = 1;
  }

  return value;
}

/*
 * call-seq:
 *  recovery
 *
 * Should this parser recover from structural errors? It will not stop processing
 * file on structural errors if set to true
 */
static VALUE
get_recovery(VALUE self)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(self);

  if (ctxt->recovery == 0) {
    return Qfalse;
  } else {
    return Qtrue;
  }
}

void
noko_init_xml_sax_parser_context(void)
{
  cNokogiriXmlSaxParserContext = rb_define_class_under(mNokogiriXmlSax, "ParserContext", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "io", parse_io, 2);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "memory", parse_memory, 1);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "file", parse_file, 1);

  rb_define_method(cNokogiriXmlSaxParserContext, "parse_with", parse_with, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities=", set_replace_entities, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities", get_replace_entities, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery=", set_recovery, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery", get_recovery, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "line", line, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "column", column, 0);

  id_read = rb_intern("read");
}
