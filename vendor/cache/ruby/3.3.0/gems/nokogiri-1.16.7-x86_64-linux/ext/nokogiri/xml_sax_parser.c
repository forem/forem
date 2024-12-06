#include <nokogiri.h>

VALUE cNokogiriXmlSaxParser ;

static ID id_start_document, id_end_document, id_start_element, id_end_element;
static ID id_start_element_namespace, id_end_element_namespace;
static ID id_comment, id_characters, id_xmldecl, id_error, id_warning;
static ID id_cdata_block;
static ID id_processing_instruction;

static void
start_document(void *ctx)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");

  xmlParserCtxtPtr ctxt = NOKOGIRI_SAX_CTXT(ctx);

  if (NULL != ctxt && ctxt->html != 1) {
    if (ctxt->standalone != -1) { /* -1 means there was no declaration */
      VALUE encoding = Qnil ;
      VALUE standalone = Qnil;
      VALUE version;
      if (ctxt->encoding) {
        encoding = NOKOGIRI_STR_NEW2(ctxt->encoding) ;
      } else if (ctxt->input && ctxt->input->encoding) {
        encoding = NOKOGIRI_STR_NEW2(ctxt->input->encoding) ;
      }

      version = ctxt->version ? NOKOGIRI_STR_NEW2(ctxt->version) : Qnil;

      switch (ctxt->standalone) {
        case 0:
          standalone = NOKOGIRI_STR_NEW2("no");
          break;
        case 1:
          standalone = NOKOGIRI_STR_NEW2("yes");
          break;
      }

      rb_funcall(doc, id_xmldecl, 3, version, encoding, standalone);
    }
  }

  rb_funcall(doc, id_start_document, 0);
}

static void
end_document(void *ctx)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  rb_funcall(doc, id_end_document, 0);
}

static void
start_element(void *ctx, const xmlChar *name, const xmlChar **atts)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE attributes = rb_ary_new();
  const xmlChar *attr;
  int i = 0;
  if (atts) {
    while ((attr = atts[i]) != NULL) {
      const xmlChar *val = atts[i + 1];
      VALUE value = val != NULL ? NOKOGIRI_STR_NEW2(val) : Qnil;
      rb_ary_push(attributes, rb_ary_new3(2, NOKOGIRI_STR_NEW2(attr), value));
      i += 2;
    }
  }

  rb_funcall(doc,
             id_start_element,
             2,
             NOKOGIRI_STR_NEW2(name),
             attributes
            );
}

static void
end_element(void *ctx, const xmlChar *name)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  rb_funcall(doc, id_end_element, 1, NOKOGIRI_STR_NEW2(name));
}

static VALUE
attributes_as_array(int attributes_len, const xmlChar **c_attributes)
{
  VALUE rb_array = rb_ary_new2((long)attributes_len);
  VALUE cNokogiriXmlSaxParserAttribute;

  cNokogiriXmlSaxParserAttribute = rb_const_get_at(cNokogiriXmlSaxParser, rb_intern("Attribute"));
  if (c_attributes) {
    /* Each attribute is an array of [localname, prefix, URI, value, end] */
    int i;
    for (i = 0; i < attributes_len * 5; i += 5) {
      VALUE rb_constructor_args[4], rb_attribute;

      rb_constructor_args[0] = RBSTR_OR_QNIL(c_attributes[i + 0]); /* localname */
      rb_constructor_args[1] = RBSTR_OR_QNIL(c_attributes[i + 1]); /* prefix */
      rb_constructor_args[2] = RBSTR_OR_QNIL(c_attributes[i + 2]); /* URI */

      /* value */
      rb_constructor_args[3] = NOKOGIRI_STR_NEW((const char *)c_attributes[i + 3],
                               (c_attributes[i + 4] - c_attributes[i + 3]));

      rb_attribute = rb_class_new_instance(4, rb_constructor_args, cNokogiriXmlSaxParserAttribute);
      rb_ary_push(rb_array, rb_attribute);
    }
  }

  return rb_array;
}

static void
start_element_ns(
  void *ctx,
  const xmlChar *localname,
  const xmlChar *prefix,
  const xmlChar *uri,
  int nb_namespaces,
  const xmlChar **namespaces,
  int nb_attributes,
  int nb_defaulted,
  const xmlChar **attributes)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");

  VALUE attribute_ary = attributes_as_array(nb_attributes, attributes);

  VALUE ns_list = rb_ary_new2((long)nb_namespaces);

  if (namespaces) {
    int i;
    for (i = 0; i < nb_namespaces * 2; i += 2) {
      rb_ary_push(ns_list,
                  rb_ary_new3((long)2,
                              RBSTR_OR_QNIL(namespaces[i + 0]),
                              RBSTR_OR_QNIL(namespaces[i + 1])
                             )
                 );
    }
  }

  rb_funcall(doc,
             id_start_element_namespace,
             5,
             NOKOGIRI_STR_NEW2(localname),
             attribute_ary,
             RBSTR_OR_QNIL(prefix),
             RBSTR_OR_QNIL(uri),
             ns_list
            );
}

/**
 * end_element_ns was borrowed heavily from libxml-ruby.
 */
static void
end_element_ns(
  void *ctx,
  const xmlChar *localname,
  const xmlChar *prefix,
  const xmlChar *uri)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");

  rb_funcall(doc, id_end_element_namespace, 3,
             NOKOGIRI_STR_NEW2(localname),
             RBSTR_OR_QNIL(prefix),
             RBSTR_OR_QNIL(uri)
            );
}

static void
characters_func(void *ctx, const xmlChar *ch, int len)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE str = NOKOGIRI_STR_NEW(ch, len);
  rb_funcall(doc, id_characters, 1, str);
}

static void
comment_func(void *ctx, const xmlChar *value)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE str = NOKOGIRI_STR_NEW2(value);
  rb_funcall(doc, id_comment, 1, str);
}

PRINTFLIKE_DECL(2, 3)
static void
warning_func(void *ctx, const char *msg, ...)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE rb_message;

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  rb_message = rb_sprintf("warning_func: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  rb_message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_funcall(doc, id_warning, 1, rb_message);
}

PRINTFLIKE_DECL(2, 3)
static void
error_func(void *ctx, const char *msg, ...)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE rb_message;

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  rb_message = rb_sprintf("error_func: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  rb_message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_funcall(doc, id_error, 1, rb_message);
}

static void
cdata_block(void *ctx, const xmlChar *value, int len)
{
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");
  VALUE string = NOKOGIRI_STR_NEW(value, len);
  rb_funcall(doc, id_cdata_block, 1, string);
}

static void
processing_instruction(void *ctx, const xmlChar *name, const xmlChar *content)
{
  VALUE rb_content;
  VALUE self = NOKOGIRI_SAX_SELF(ctx);
  VALUE doc = rb_iv_get(self, "@document");

  rb_content = content ? NOKOGIRI_STR_NEW2(content) : Qnil;

  rb_funcall(doc,
             id_processing_instruction,
             2,
             NOKOGIRI_STR_NEW2(name),
             rb_content
            );
}

static size_t
memsize(const void *data)
{
  return sizeof(xmlSAXHandler);
}

/* Used by Nokogiri::XML::SAX::Parser and Nokogiri::HTML::SAX::Parser */
static const rb_data_type_t noko_sax_handler_type = {
  .wrap_struct_name = "Nokogiri::SAXHandler",
  .function = {
    .dfree = RUBY_TYPED_DEFAULT_FREE,
    .dsize = memsize
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static VALUE
allocate(VALUE klass)
{
  xmlSAXHandlerPtr handler;
  VALUE self = TypedData_Make_Struct(klass, xmlSAXHandler, &noko_sax_handler_type, handler);

  handler->startDocument = start_document;
  handler->endDocument = end_document;
  handler->startElement = start_element;
  handler->endElement = end_element;
  handler->startElementNs = start_element_ns;
  handler->endElementNs = end_element_ns;
  handler->characters = characters_func;
  handler->comment = comment_func;
  handler->warning = warning_func;
  handler->error = error_func;
  handler->cdataBlock = cdata_block;
  handler->processingInstruction = processing_instruction;
  handler->initialized = XML_SAX2_MAGIC;

  return self;
}

xmlSAXHandlerPtr
noko_sax_handler_unwrap(VALUE rb_sax_handler)
{
  xmlSAXHandlerPtr c_sax_handler;
  TypedData_Get_Struct(rb_sax_handler, xmlSAXHandler, &noko_sax_handler_type, c_sax_handler);
  return c_sax_handler;
}

void
noko_init_xml_sax_parser(void)
{
  cNokogiriXmlSaxParser = rb_define_class_under(mNokogiriXmlSax, "Parser", rb_cObject);

  rb_define_alloc_func(cNokogiriXmlSaxParser, allocate);

  id_start_document = rb_intern("start_document");
  id_end_document = rb_intern("end_document");
  id_start_element = rb_intern("start_element");
  id_end_element = rb_intern("end_element");
  id_comment = rb_intern("comment");
  id_characters = rb_intern("characters");
  id_xmldecl = rb_intern("xmldecl");
  id_error = rb_intern("error");
  id_warning = rb_intern("warning");
  id_cdata_block = rb_intern("cdata_block");
  id_start_element_namespace = rb_intern("start_element_namespace");
  id_end_element_namespace = rb_intern("end_element_namespace");
  id_processing_instruction = rb_intern("processing_instruction");
}
