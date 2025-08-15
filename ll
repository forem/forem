Service: forem-db
Resource: SHOW TIME ZONE
Error: 0
Start: 1755179977199543040
End: 1755179977199950080
Duration: 0.00040800000715535134
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.201915 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4582761801700147376
Parent ID: 0
Trace ID: 1380712150843960343
Type: sql
Service: forem-db
Resource: SELECT c.relname FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = ANY (current_schemas(false)) AND c.relkind IN ('r','v','m','p','f')
Error: 0
Start: 1755179977200839936
End: 1755179977201701120
Duration: 0.000862000000779517
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.204198 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 217170317797541695
Parent ID: 0
Trace ID: 1521556852564407217
Type: sql
Service: forem-db
Resource: SELECT a.attname, format_type(a.atttypid, a.atttypmod),
       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
       c.collname, col_description(a.attrelid, a.attnum) AS comment,
       attgenerated as attgenerated
  FROM pg_attribute a
  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
  LEFT JOIN pg_type t ON a.atttypid = t.oid
  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
 WHERE a.attrelid = '"ar_internal_metadata"'::regclass
   AND a.attnum > 0 AND NOT a.attisdropped
 ORDER BY a.attnum

Error: 0
Start: 1755179977202394112
End: 1755179977203955968
Duration: 0.001564000005600974
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.206570 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 2624757370175437056
Parent ID: 0
Trace ID: 1934526631408119316
Type: sql
Service: forem-db
Resource: SHOW search_path
Error: 0
Start: 1755179977205779968
End: 1755179977206360064
Duration: 0.0005789999995613471
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.208036 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4365140553861400403
Parent ID: 0
Trace ID: 2752732714761724860
Type: sql
Service: forem-db
Resource: SELECT "ar_internal_metadata"."value" FROM "ar_internal_metadata" WHERE "ar_internal_metadata"."key" = $1 LIMIT $2
Error: 0
Start: 1755179977207223040
End: 1755179977207820032
Duration: 0.0005970000056549907
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.217623 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 1145064993511275492
Parent ID: 0
Trace ID: 2049715181859343222
Type: sql
Service: forem-db
Resource: SET client_min_messages TO 'warning'
Error: 0
Start: 1755179977216971008
End: 1755179977217345024
Duration: 0.00037399999564513564
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.218294 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4486502952965557385
Parent ID: 0
Trace ID: 2782766532884546917
Type: sql
Service: forem-db
Resource: SET standard_conforming_strings = on
Error: 0
Start: 1755179977217724928
End: 1755179977218136064
Duration: 0.00041099998634308577
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.219002 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 1816080074616255427
Parent ID: 0
Trace ID: 1140959878143839749
Type: sql
Service: forem-db
Resource: SET intervalstyle = iso_8601
Error: 0
Start: 1755179977218368000
End: 1755179977218758912
Duration: 0.0003929999948013574
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.219752 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 537584961696229111
Parent ID: 0
Trace ID: 737440811348964575
Type: sql
Service: forem-db
Resource: SET SESSION statement_timeout TO 10000
Error: 0
Start: 1755179977219105024
End: 1755179977219511040
Duration: 0.00040699999954085797
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.220509 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 720987709038060122
Parent ID: 0
Trace ID: 2646948842638860773
Type: sql
Service: forem-db
Resource: SET SESSION timezone TO 'UTC'
Error: 0
Start: 1755179977219844096
End: 1755179977220315904
Duration: 0.00047199999971780926
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.221786 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4010293023746444914
Parent ID: 0
Trace ID: 1881012439555084509
Type: sql
Service: forem-db
Resource: SELECT t.oid, t.typname
FROM pg_type as t
WHERE t.typname IN ('int2', 'int4', 'int8', 'oid', 'float4', 'float8', 'numeric', 'bool', 'timestamp', 'timestamptz')

Error: 0
Start: 1755179977220645120
End: 1755179977221594112
Duration: 0.0009499999869149178
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.222998 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 3566990845148019334
Parent ID: 0
Trace ID: 2402172415724591684
Type: sql
Service: forem-db
Resource: SET client_min_messages TO 'warning'
Error: 0
Start: 1755179977222302976
End: 1755179977222787072
Duration: 0.0004830000107176602
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.223623 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4376974831214312885
Parent ID: 0
Trace ID: 85993337233058830
Type: sql
Service: forem-db
Resource: SET standard_conforming_strings = on
Error: 0
Start: 1755179977223090944
End: 1755179977223454976
Duration: 0.0003639999922597781
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.224647 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 898729065514004194
Parent ID: 0
Trace ID: 4343824037031100729
Type: sql
Service: forem-db
Resource: SET intervalstyle = iso_8601
Error: 0
Start: 1755179977223695104
End: 1755179977224112896
Duration: 0.0004199999966658652
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.225360 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 1897944853246023149
Parent ID: 0
Trace ID: 2934423260499697209
Type: sql
Service: forem-db
Resource: SET SESSION statement_timeout TO 10000
Error: 0
Start: 1755179977224771072
End: 1755179977225152000
Duration: 0.0003809999907389283
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.225872 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 3715388659408349934
Parent ID: 0
Trace ID: 1274946260103456449
Type: sql
Service: forem-db
Resource: SET SESSION timezone TO 'UTC'
Error: 0
Start: 1755179977225445888
End: 1755179977225724928
Duration: 0.00027800000680144876
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.227259 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4097970508079772995
Parent ID: 0
Trace ID: 3903406332752488349
Type: sql
Service: forem-db
Resource: SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype
FROM pg_type as t
LEFT JOIN pg_range as r ON oid = rngtypid
WHERE
  t.typname IN ('int2', 'int4', 'int8', 'oid', 'float4', 'float8', 'text', 'varchar', 'char', 'name', 'bpchar', 'bool', 'bit', 'varbit', 'date', 'money', 'bytea', 'point', 'hstore', 'json', 'jsonb', 'cidr', 'inet', 'uuid', 'xml', 'tsvector', 'macaddr', 'citext', 'ltree', 'line', 'lseg', 'box', 'path', 'polygon', 'circle', 'time', 'timestamp', 'timestamptz', 'numeric', 'interval')

Error: 0
Start: 1755179977226018048
End: 1755179977227034880
Duration: 0.0010189999884460121
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.228248 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 3070599091007200419
Parent ID: 0
Trace ID: 3465575567659339995
Type: sql
Service: forem-db
Resource: SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype
FROM pg_type as t
LEFT JOIN pg_range as r ON oid = rngtypid
WHERE
  t.typtype IN ('r', 'e', 'd')

Error: 0
Start: 1755179977227432960
End: 1755179977228067072
Duration: 0.0006350000039674342
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.229592 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4383008131181740660
Parent ID: 0
Trace ID: 1653266492345988676
Type: sql
Service: forem-db
Resource: SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype
FROM pg_type as t
LEFT JOIN pg_range as r ON oid = rngtypid
WHERE
  t.typelem IN (16, 17, 18, 19, 20, 21, 23, 25, 26, 114, 142, 600, 601, 602, 603, 604, 628, 700, 701, 718, 790, 829, 869, 650, 1042, 1043, 1082, 1083, 1114, 1184, 1186, 1560, 1562, 1700, 2950, 3614, 3802, 184864, 184969, 13197, 13200, 13202, 13207, 13209, 3904, 3906, 3908, 3910, 3912, 3926)

Error: 0
Start: 1755179977228485888
End: 1755179977229401088
Duration: 0.0009160000045085326
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.230664 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 4499706745613822754
Parent ID: 0
Trace ID: 254572554218539571
Type: sql
Service: forem-db
Resource: SHOW TIME ZONE
Error: 0
Start: 1755179977229844992
End: 1755179977230212096
Duration: 0.00036700000055134296
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.241373 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 2256559722453417072
Parent ID: 0
Trace ID: 1845370686965036708
Type: sql
Service: forem-db
Resource: SELECT c.relname FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = ANY (current_schemas(false)) AND c.relname = 'schema_migrations' AND c.relkind IN ('r','v','m','p','f')
Error: 0
Start: 1755179977240324096
End: 1755179977241111040
Duration: 0.00078600000415463
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.243173 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 1318804505229981102
Parent ID: 0
Trace ID: 3320365848699064633
Type: sql
Service: forem-db
Resource: SELECT a.attname, format_type(a.atttypid, a.atttypmod),
       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
       c.collname, col_description(a.attrelid, a.attnum) AS comment,
       attgenerated as attgenerated
  FROM pg_attribute a
  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
  LEFT JOIN pg_type t ON a.atttypid = t.oid
  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
 WHERE a.attrelid = '"schema_migrations"'::regclass
   AND a.attnum > 0 AND NOT a.attisdropped
 ORDER BY a.attnum

Error: 0
Start: 1755179977241711104
End: 1755179977242957056
Duration: 0.0012469999928725883
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.244952 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/tracing/tracer.rb:543:in `write') Writing 1 spans (enabled: true)
[
 Name: postgres.query
Span ID: 551560696903222197
Parent ID: 0
Trace ID: 554239966334210056
Type: sql
Service: forem-db
Resource: SELECT "schema_migrations"."version" FROM "schema_migrations" ORDER BY "schema_migrations"."version" ASC
Error: 0
Start: 1755179977243576064
End: 1755179977244687104
Duration: 0.001113999998779036
Tags: [
   env => ci,
   component => active_record,
   operation => sql,
   _dd.base_service => forem,
   active_record.db.vendor => postgres,
   db.instance => Forem_test0,
   active_record.db.name => Forem_test0,
   out.host => localhost,
   _dd.origin => ]
Metrics: [
   out.port => 54323.0,
   _dd.top_level => 1.0]
Metastruct: []]

D, [2025-08-15T02:59:37.662552 #99725] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/core/telemetry/worker.rb:169:in `flush_events') Sending 2 telemetry events
D, [2025-08-15T02:59:37.781451 #99725] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/core/telemetry/emitter.rb:34:in `request') Telemetry sent for event `message-batch` (response code: 202)
D, [2025-08-15T02:59:37.897042 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/p/datadog-ci-rb/lib/datadog/ci/transport/event_platform_transport.rb:27:in `send_events') [Datadog::CI::TestVisibility::Transport] Sending 37 events...
D, [2025-08-15T02:59:37.897597 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/p/datadog-ci-rb/lib/datadog/ci/transport/event_platform_transport.rb:46:in `block in send_events') [Datadog::CI::TestVisibility::Transport] Send chunk of 37 events; payload size 22173
D, [2025-08-15T02:59:37.897860 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/p/datadog-ci-rb/lib/datadog/ci/transport/http.rb:57:in `block in request') Sending post request: host=citestcycle-intake.datadoghq.eu; port=443; ssl_enabled=true; compression_enabled=true; path=/api/v2/citestcycle; payload_size=2973
D, [2025-08-15T02:59:38.032903 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/p/datadog-ci-rb/lib/datadog/ci/transport/http.rb:64:in `block in request') Received server response: Datadog::CI::Transport::Adapters::Net::Response ok?:true unsupported?:false, not_found?:false, client_error?:false, server_error?:false, internal_error?:, payload:{}, http_response:#<Net::HTTPAccepted:0x00000001261bdf38>
Coverage report generated for RSpec to /Users/andrey.marchenko/qa/forem/coverage/simplecov. 1867 / 31298 LOC (5.97%) covered.
D, [2025-08-15T02:59:39.518140 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/core/telemetry/worker.rb:169:in `flush_events') Sending 3 telemetry events
D, [2025-08-15T02:59:39.675211 #99927] DEBUG -- datadog: [datadog] (/Users/andrey.marchenko/.rbenv/versions/3.3.0/lib/ruby/gems/3.3.0/bundler/gems/dd-trace-rb-7fbb42dc2459/lib/datadog/core/telemetry/emitter.rb:34:in `request') Telemetry sent for event `message-batch` (response code: 202)

An error occurred while loading ..
Failure/Error: __send__(method, file)

LoadError:
  cannot load such file -- /Users/andrey.marchenko/qa/forem
# /Users/andrey.marchenko/p/datadog-ci-rb/lib/datadog/ci/contrib/knapsack/runner.rb:34:in `knapsack__run_specs'
W, [2025-08-15T02:59:40.873425 #99725]  WARN -- : [knapsack_pro] RSpec wants to quit.
I, [2025-08-15T02:59:40.874436 #99725]  INFO -- : [knapsack_pro] To retry the last batch of tests fetched from the Queue API, please run the following command on your machine:
I, [2025-08-15T02:59:40.874497 #99725]  INFO -- : [knapsack_pro] bundle exec rspec --format progress --require rails_helper --default-path spec ""


Finished in 11.28 seconds (files took 4.86 seconds to load)
0 examples, 0 failures, 1 error occurred outside of examples
