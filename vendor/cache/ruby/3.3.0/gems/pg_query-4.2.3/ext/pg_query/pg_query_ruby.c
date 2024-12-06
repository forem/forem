#include "pg_query.h"
#include "xxhash/xxhash.h"
#include <ruby.h>

void raise_ruby_parse_error(PgQueryProtobufParseResult result);
void raise_ruby_normalize_error(PgQueryNormalizeResult result);
void raise_ruby_fingerprint_error(PgQueryFingerprintResult result);
void raise_ruby_scan_error(PgQueryScanResult result);

VALUE pg_query_ruby_parse_protobuf(VALUE self, VALUE input);
VALUE pg_query_ruby_deparse_protobuf(VALUE self, VALUE input);
VALUE pg_query_ruby_normalize(VALUE self, VALUE input);
VALUE pg_query_ruby_fingerprint(VALUE self, VALUE input);
VALUE pg_query_ruby_scan(VALUE self, VALUE input);
VALUE pg_query_ruby_hash_xxh3_64(VALUE self, VALUE input, VALUE seed);

__attribute__((visibility ("default"))) void Init_pg_query(void)
{
	VALUE cPgQuery;

	cPgQuery = rb_const_get(rb_cObject, rb_intern("PgQuery"));

	rb_define_singleton_method(cPgQuery, "parse_protobuf", pg_query_ruby_parse_protobuf, 1);
	rb_define_singleton_method(cPgQuery, "deparse_protobuf", pg_query_ruby_deparse_protobuf, 1);
	rb_define_singleton_method(cPgQuery, "normalize", pg_query_ruby_normalize, 1);
	rb_define_singleton_method(cPgQuery, "fingerprint", pg_query_ruby_fingerprint, 1);
	rb_define_singleton_method(cPgQuery, "_raw_scan", pg_query_ruby_scan, 1);
	rb_define_singleton_method(cPgQuery, "hash_xxh3_64", pg_query_ruby_hash_xxh3_64, 2);
	rb_define_const(cPgQuery, "PG_VERSION", rb_str_new2(PG_VERSION));
	rb_define_const(cPgQuery, "PG_MAJORVERSION", rb_str_new2(PG_MAJORVERSION));
	rb_define_const(cPgQuery, "PG_VERSION_NUM", INT2NUM(PG_VERSION_NUM));
}

void raise_ruby_parse_error(PgQueryProtobufParseResult result)
{
	VALUE cPgQuery, cParseError;
	VALUE args[4];

	cPgQuery    = rb_const_get(rb_cObject, rb_intern("PgQuery"));
	cParseError = rb_const_get_at(cPgQuery, rb_intern("ParseError"));

	args[0] = rb_str_new2(result.error->message);
	args[1] = rb_str_new2(result.error->filename);
	args[2] = INT2NUM(result.error->lineno);
	args[3] = INT2NUM(result.error->cursorpos);

	pg_query_free_protobuf_parse_result(result);

	rb_exc_raise(rb_class_new_instance(4, args, cParseError));
}

void raise_ruby_deparse_error(PgQueryDeparseResult result)
{
	VALUE cPgQuery, cParseError;
	VALUE args[4];

	cPgQuery    = rb_const_get(rb_cObject, rb_intern("PgQuery"));
	cParseError = rb_const_get_at(cPgQuery, rb_intern("ParseError"));

	args[0] = rb_str_new2(result.error->message);
	args[1] = rb_str_new2(result.error->filename);
	args[2] = INT2NUM(result.error->lineno);
	args[3] = INT2NUM(result.error->cursorpos);

	pg_query_free_deparse_result(result);

	rb_exc_raise(rb_class_new_instance(4, args, cParseError));
}

void raise_ruby_normalize_error(PgQueryNormalizeResult result)
{
	VALUE cPgQuery, cParseError;
	VALUE args[4];

	cPgQuery    = rb_const_get(rb_cObject, rb_intern("PgQuery"));
	cParseError = rb_const_get_at(cPgQuery, rb_intern("ParseError"));

	args[0] = rb_str_new2(result.error->message);
	args[1] = rb_str_new2(result.error->filename);
	args[2] = INT2NUM(result.error->lineno);
	args[3] = INT2NUM(result.error->cursorpos);

	pg_query_free_normalize_result(result);

	rb_exc_raise(rb_class_new_instance(4, args, cParseError));
}

void raise_ruby_fingerprint_error(PgQueryFingerprintResult result)
{
	VALUE cPgQuery, cParseError;
	VALUE args[4];

	cPgQuery    = rb_const_get(rb_cObject, rb_intern("PgQuery"));
	cParseError = rb_const_get_at(cPgQuery, rb_intern("ParseError"));

	args[0] = rb_str_new2(result.error->message);
	args[1] = rb_str_new2(result.error->filename);
	args[2] = INT2NUM(result.error->lineno);
	args[3] = INT2NUM(result.error->cursorpos);

	pg_query_free_fingerprint_result(result);

	rb_exc_raise(rb_class_new_instance(4, args, cParseError));
}

void raise_ruby_scan_error(PgQueryScanResult result)
{
	VALUE cPgQuery, cScanError;
	VALUE args[4];

	cPgQuery   = rb_const_get(rb_cObject, rb_intern("PgQuery"));
	cScanError = rb_const_get_at(cPgQuery, rb_intern("ScanError"));

	args[0] = rb_str_new2(result.error->message);
	args[1] = rb_str_new2(result.error->filename);
	args[2] = INT2NUM(result.error->lineno);
	args[3] = INT2NUM(result.error->cursorpos);

	pg_query_free_scan_result(result);

	rb_exc_raise(rb_class_new_instance(4, args, cScanError));
}

VALUE pg_query_ruby_parse_protobuf(VALUE self, VALUE input)
{
	Check_Type(input, T_STRING);

	VALUE output;
	PgQueryProtobufParseResult result = pg_query_parse_protobuf(StringValueCStr(input));

	if (result.error) raise_ruby_parse_error(result);

	output = rb_ary_new();

	rb_ary_push(output, rb_str_new(result.parse_tree.data, result.parse_tree.len));
	rb_ary_push(output, rb_str_new2(result.stderr_buffer));

	pg_query_free_protobuf_parse_result(result);

	return output;
}

VALUE pg_query_ruby_deparse_protobuf(VALUE self, VALUE input)
{
	Check_Type(input, T_STRING);

	VALUE output;
	PgQueryProtobuf pbuf = {0};
	PgQueryDeparseResult result = {0};

	pbuf.data = StringValuePtr(input);
	pbuf.len = RSTRING_LEN(input);
	result = pg_query_deparse_protobuf(pbuf);

	if (result.error) raise_ruby_deparse_error(result);

	output = rb_str_new2(result.query);

	pg_query_free_deparse_result(result);

	return output;
}

VALUE pg_query_ruby_normalize(VALUE self, VALUE input)
{
	Check_Type(input, T_STRING);

	VALUE output;
	PgQueryNormalizeResult result = pg_query_normalize(StringValueCStr(input));

	if (result.error) raise_ruby_normalize_error(result);

	output = rb_str_new2(result.normalized_query);

	pg_query_free_normalize_result(result);

	return output;
}

VALUE pg_query_ruby_fingerprint(VALUE self, VALUE input)
{
	Check_Type(input, T_STRING);

	VALUE output;
	PgQueryFingerprintResult result = pg_query_fingerprint(StringValueCStr(input));

	if (result.error) raise_ruby_fingerprint_error(result);

	if (result.fingerprint_str) {
		output = rb_str_new2(result.fingerprint_str);
	} else {
		output = Qnil;
	}

	pg_query_free_fingerprint_result(result);

	return output;
}

VALUE pg_query_ruby_scan(VALUE self, VALUE input)
{
	Check_Type(input, T_STRING);

	VALUE output;
	PgQueryScanResult result = pg_query_scan(StringValueCStr(input));

	if (result.error) raise_ruby_scan_error(result);

	output = rb_ary_new();

	rb_ary_push(output, rb_str_new(result.pbuf.data, result.pbuf.len));
	rb_ary_push(output, rb_str_new2(result.stderr_buffer));

	pg_query_free_scan_result(result);

	return output;
}

VALUE pg_query_ruby_hash_xxh3_64(VALUE self, VALUE input, VALUE seed)
{
	Check_Type(input, T_STRING);
	Check_Type(seed, T_FIXNUM);

	return ULONG2NUM(XXH3_64bits_withSeed(StringValuePtr(input), RSTRING_LEN(input), NUM2ULONG(seed)));
}
