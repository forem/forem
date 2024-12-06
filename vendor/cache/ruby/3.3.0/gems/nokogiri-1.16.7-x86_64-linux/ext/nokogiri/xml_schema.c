#include <nokogiri.h>

VALUE cNokogiriXmlSchema;

static void
xml_schema_deallocate(void *data)
{
  xmlSchemaPtr schema = data;
  xmlSchemaFree(schema);
}

static const rb_data_type_t xml_schema_type = {
  .wrap_struct_name = "Nokogiri::XML::Schema",
  .function = {
    .dfree = xml_schema_deallocate,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * call-seq:
 *  validate_document(document)
 *
 * Validate a Nokogiri::XML::Document against this Schema.
 */
static VALUE
validate_document(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlSchemaPtr schema;
  xmlSchemaValidCtxtPtr valid_ctxt;
  VALUE errors;

  TypedData_Get_Struct(self, xmlSchema, &xml_schema_type, schema);
  doc = noko_xml_document_unwrap(document);

  errors = rb_ary_new();

  valid_ctxt = xmlSchemaNewValidCtxt(schema);

  if (NULL == valid_ctxt) {
    /* we have a problem */
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

#ifdef HAVE_XMLSCHEMASETVALIDSTRUCTUREDERRORS
  xmlSchemaSetValidStructuredErrors(
    valid_ctxt,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlSchemaValidateDoc(valid_ctxt, doc);

  xmlSchemaFreeValidCtxt(valid_ctxt);

  return errors;
}

/*
 * call-seq:
 *  validate_file(filename)
 *
 * Validate a file against this Schema.
 */
static VALUE
validate_file(VALUE self, VALUE rb_filename)
{
  xmlSchemaPtr schema;
  xmlSchemaValidCtxtPtr valid_ctxt;
  const char *filename ;
  VALUE errors;

  TypedData_Get_Struct(self, xmlSchema, &xml_schema_type, schema);
  filename = (const char *)StringValueCStr(rb_filename) ;

  errors = rb_ary_new();

  valid_ctxt = xmlSchemaNewValidCtxt(schema);

  if (NULL == valid_ctxt) {
    /* we have a problem */
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

#ifdef HAVE_XMLSCHEMASETVALIDSTRUCTUREDERRORS
  xmlSchemaSetValidStructuredErrors(
    valid_ctxt,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlSchemaValidateFile(valid_ctxt, filename, 0);

  xmlSchemaFreeValidCtxt(valid_ctxt);

  return errors;
}

static VALUE
xml_schema_parse_schema(
  VALUE klass,
  xmlSchemaParserCtxtPtr c_parser_context,
  VALUE rb_parse_options
)
{
  VALUE rb_errors;
  int parse_options_int;
  xmlSchemaPtr c_schema;
  xmlExternalEntityLoader old_loader = 0;
  VALUE rb_schema;

  if (NIL_P(rb_parse_options)) {
    rb_parse_options = rb_const_get_at(
                         rb_const_get_at(mNokogiriXml, rb_intern("ParseOptions")),
                         rb_intern("DEFAULT_SCHEMA")
                       );
  }

  rb_errors = rb_ary_new();
  xmlSetStructuredErrorFunc((void *)rb_errors, Nokogiri_error_array_pusher);

#ifdef HAVE_XMLSCHEMASETPARSERSTRUCTUREDERRORS
  xmlSchemaSetParserStructuredErrors(
    c_parser_context,
    Nokogiri_error_array_pusher,
    (void *)rb_errors
  );
#endif

  parse_options_int = (int)NUM2INT(rb_funcall(rb_parse_options, rb_intern("to_i"), 0));
  if (parse_options_int & XML_PARSE_NONET) {
    old_loader = xmlGetExternalEntityLoader();
    xmlSetExternalEntityLoader(xmlNoNetExternalEntityLoader);
  }

  c_schema = xmlSchemaParse(c_parser_context);

  if (old_loader) {
    xmlSetExternalEntityLoader(old_loader);
  }

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlSchemaFreeParserCtxt(c_parser_context);

  if (NULL == c_schema) {
    xmlErrorConstPtr error = xmlGetLastError();
    if (error) {
      Nokogiri_error_raise(NULL, error);
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }

    return Qnil;
  }

  rb_schema = TypedData_Wrap_Struct(klass, &xml_schema_type, c_schema);
  rb_iv_set(rb_schema, "@errors", rb_errors);
  rb_iv_set(rb_schema, "@parse_options", rb_parse_options);

  return rb_schema;
}

/*
 * call-seq:
 *   read_memory(string) → Nokogiri::XML::Schema
 *
 * Create a new schema parsed from the contents of +string+
 *
 * [Parameters]
 * - +string+: String containing XML to be parsed as a schema
 *
 * [Returns] Nokogiri::XML::Schema
 */
static VALUE
read_memory(int argc, VALUE *argv, VALUE klass)
{
  VALUE rb_content;
  VALUE rb_parse_options;
  xmlSchemaParserCtxtPtr c_parser_context;

  rb_scan_args(argc, argv, "11", &rb_content, &rb_parse_options);

  c_parser_context = xmlSchemaNewMemParserCtxt(
                       (const char *)StringValuePtr(rb_content),
                       (int)RSTRING_LEN(rb_content)
                     );

  return xml_schema_parse_schema(klass, c_parser_context, rb_parse_options);
}

/*
 * call-seq:
 *   from_document(document) → Nokogiri::XML::Schema
 *
 * Create a new schema parsed from the +document+.
 *
 * [Parameters]
 * - +document+: Nokogiri::XML::Document to be parsed
 *
 * [Returns] Nokogiri::XML::Schema
 */
static VALUE
rb_xml_schema_s_from_document(int argc, VALUE *argv, VALUE klass)
{
  VALUE rb_document;
  VALUE rb_parse_options;
  VALUE rb_schema;
  xmlDocPtr c_document;
  xmlSchemaParserCtxtPtr c_parser_context;
  int defensive_copy_p = 0;

  rb_scan_args(argc, argv, "11", &rb_document, &rb_parse_options);

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlNode)) {
    rb_raise(rb_eTypeError,
             "expected parameter to be a Nokogiri::XML::Document, received %"PRIsVALUE,
             rb_obj_class(rb_document));
  }

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    xmlNodePtr deprecated_node_type_arg;
    NOKO_WARN_DEPRECATION("Passing a Node as the first parameter to Schema.from_document is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    Noko_Node_Get_Struct(rb_document, xmlNode, deprecated_node_type_arg);
    c_document = deprecated_node_type_arg->doc;
  } else {
    c_document = noko_xml_document_unwrap(rb_document);
  }

  if (noko_xml_document_has_wrapped_blank_nodes_p(c_document)) {
    // see https://github.com/sparklemotion/nokogiri/pull/2001
    c_document = xmlCopyDoc(c_document, 1);
    defensive_copy_p = 1;
  }

  c_parser_context = xmlSchemaNewDocParserCtxt(c_document);
  rb_schema = xml_schema_parse_schema(klass, c_parser_context, rb_parse_options);

  if (defensive_copy_p) {
    xmlFreeDoc(c_document);
    c_document = NULL;
  }

  return rb_schema;
}

void
noko_init_xml_schema(void)
{
  cNokogiriXmlSchema = rb_define_class_under(mNokogiriXml, "Schema", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSchema);

  rb_define_singleton_method(cNokogiriXmlSchema, "read_memory", read_memory, -1);
  rb_define_singleton_method(cNokogiriXmlSchema, "from_document", rb_xml_schema_s_from_document, -1);

  rb_define_private_method(cNokogiriXmlSchema, "validate_document", validate_document, 1);
  rb_define_private_method(cNokogiriXmlSchema, "validate_file",     validate_file, 1);
}
