#include <nokogiri.h>

VALUE cNokogiriXmlDocumentFragment;

/*
 * call-seq:
 *  new(document)
 *
 * Create a new DocumentFragment element on the +document+
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  xmlNodePtr node;
  VALUE document;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "1*", &document, &rest);

  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewDocFragment(xml_doc->doc);

  noko_xml_document_pin_node(node);

  rb_node = noko_xml_node_wrap(klass, node);
  rb_obj_call_init(rb_node, argc, argv);

  return rb_node;
}

void
noko_init_xml_document_fragment(void)
{
  assert(cNokogiriXmlNode);
  /*
   * DocumentFragment represents a DocumentFragment node in an xml document.
   */
  cNokogiriXmlDocumentFragment = rb_define_class_under(mNokogiriXml, "DocumentFragment", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlDocumentFragment, "new", new, -1);
}
