#include <nokogiri.h>

VALUE cNokogiriHtml4SaxParserContext ;

static VALUE
parse_memory(VALUE klass, VALUE data, VALUE encoding)
{
  htmlParserCtxtPtr ctxt;

  Check_Type(data, T_STRING);

  if (!(int)RSTRING_LEN(data)) {
    rb_raise(rb_eRuntimeError, "data cannot be empty");
  }

  ctxt = htmlCreateMemoryParserCtxt(StringValuePtr(data),
                                    (int)RSTRING_LEN(data));
  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  if (RTEST(encoding)) {
    xmlCharEncodingHandlerPtr enc = xmlFindCharEncodingHandler(StringValueCStr(encoding));
    if (enc != NULL) {
      xmlSwitchToEncoding(ctxt, enc);
      if (ctxt->errNo == XML_ERR_UNSUPPORTED_ENCODING) {
        rb_raise(rb_eRuntimeError, "Unsupported encoding %s",
                 StringValueCStr(encoding));
      }
    }
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

static VALUE
parse_file(VALUE klass, VALUE filename, VALUE encoding)
{
  htmlParserCtxtPtr ctxt = htmlCreateFileParserCtxt(
                             StringValueCStr(filename),
                             StringValueCStr(encoding)
                           );

  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

static VALUE
parse_doc(VALUE ctxt_val)
{
  htmlParserCtxtPtr ctxt = (htmlParserCtxtPtr)ctxt_val;
  htmlParseDocument(ctxt);
  return Qnil;
}

static VALUE
parse_doc_finalize(VALUE ctxt_val)
{
  htmlParserCtxtPtr ctxt = (htmlParserCtxtPtr)ctxt_val;

  if (ctxt->myDoc) {
    xmlFreeDoc(ctxt->myDoc);
  }

  NOKOGIRI_SAX_TUPLE_DESTROY(ctxt->userData);
  return Qnil;
}

static VALUE
parse_with(VALUE self, VALUE sax_handler)
{
  htmlParserCtxtPtr ctxt;
  htmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(sax_handler, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  ctxt = noko_xml_sax_parser_context_unwrap(self);
  sax = noko_sax_handler_unwrap(sax_handler);

  ctxt->sax = sax;
  ctxt->userData = (void *)NOKOGIRI_SAX_TUPLE_NEW(ctxt, sax_handler);

  xmlSetStructuredErrorFunc(NULL, NULL);

  rb_ensure(parse_doc, (VALUE)ctxt, parse_doc_finalize, (VALUE)ctxt);

  return self;
}

void
noko_init_html_sax_parser_context(void)
{
  assert(cNokogiriXmlSaxParserContext);
  cNokogiriHtml4SaxParserContext = rb_define_class_under(mNokogiriHtml4Sax, "ParserContext",
                                   cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "memory", parse_memory, 2);
  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "file", parse_file, 2);

  rb_define_method(cNokogiriHtml4SaxParserContext, "parse_with", parse_with, 1);
}
