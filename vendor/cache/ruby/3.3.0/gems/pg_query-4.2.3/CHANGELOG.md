# Changelog

## Unreleased

* ...


## 4.2.3     2023-08-04

* Update to libpg_query 15-4.2.3
  - Fix builds when compiling with `glibc >=  2.38` [#203](https://github.com/pganalyze/libpg_query/pull/203)
  - Deparser: Add support for COALESCE and other expressions in LIMIT clause [#199](https://github.com/pganalyze/libpg_query/pull/199)

## 4.2.2     2023-07-07

* Update to libpg_query 15-4.2.2
  - Deparser: Add support for multi-statement CREATE PROCEDURE definitions
  - Deparser: Correctly quote identifier in ALTER TABLE ... ADD CONSTRAINT [x]
  - Deparser: Add support for index fillfactor within CREATE TABLE, fix SHOW ALL
* Fix builds on FreeBSD ([#292](https://github.com/pganalyze/pg_query/pull/292))
  - This was broken since 4.2.0, due to pg_query_ruby_freebsd.sym being removed by accident


## 4.2.1     2023-05-19

* Parse: Fix `ALTER INDEX my_index_name` to return `tables=[]` ([#285](https://github.com/pganalyze/pg_query/pull/285))
* Parse: Detect tables in a SELECT INTO clause as DDL tables ([#281](https://github.com/pganalyze/pg_query/pull/281))
* Add support for Ruby 3.2 ([#283](https://github.com/pganalyze/pg_query/pull/283))
* Bump up `google-protobuf` dependency to `>= 3.22.3`
  - 3.22.0 or newer is required for Ruby 3.2 support
* Update to libpg_query 15-4.2.1
  - Deparser: Handle INTERVAL correctly when used in SET statements
  - Deparser: Ensure index names are quoted as identifiers


## 4.2.0     2023-02-08

* Update to libpg_query 15-4.2.0
  - Update to PostgreSQL 15.1


## 2.2.1     2023-01-20

* Detect tables used in the query of a PREPARE statement ([#273](https://github.com/pganalyze/pg_query/pull/273))
* Expose recursive walk functionality via walk! ([#268](https://github.com/pganalyze/pg_query/pull/268))
* Retain schema in name when parsing out functions ([#272](https://github.com/pganalyze/pg_query/pull/272))


## 2.2.0     2022-11-02

* Update to libpg_query 13-2.2.0 ([#264](https://github.com/pganalyze/pg_query/pull/264))
  - Fingerprinting version 3.1
    - Fixes issue with "SELECT DISTINCT" having the same fingerprint as "SELECT"
      (fingerprints for "SELECT DISTINCT" will change with this revision)
    - Group additional DDL statements together that otherwise generate a lot of
      unique fingerprints (ListenStmt, UnlistenStmt, NotifyStmt, CreateFunctionStmt,
      FunctionParameter and DoStmt)
  - Deparser improvements
    - Prefix errors with "deparse", and remove some asserts
    - Fix potential segfault when passing invalid protobuf (RawStmt without Stmt)
  - Update to Postgres 13.8 patch release
  - Backport Xcode 14.1 build fix from upcoming 13.9 release
  - Normalize additional DDL statements
  - Add support for analyzing PL/pgSQL code inside DO blocks
  - Fix memory leak in pg_query_fingerprint error handling
  - PL/pgSQL parser: Add support for Assert, SET, COMMIT, ROLLBACK and CALL
  - Add support for parsing more operators that include a `?` character
* Support deparsing deeply nested queries ([#259](https://github.com/pganalyze/pg_query/pull/259))


## 2.1.4     2022-09-19

* Truncate: Simplify VALUES(...) lists
* Truncate: Correctly handle UPDATE and ON CONFLICT target lists
* Support complex queries with deeply nested ASTs ([#238](https://github.com/pganalyze/pg_query/pull/238))
* Find table references inside type casts
* Find function calls referenced in expression indexes ([#249](https://github.com/pganalyze/pg_query/pull/249))
* Drop `Init_pg_query` from exported symbol map ([#256](https://github.com/pganalyze/pg_query/pull/256))


## 2.1.3     2022-01-28

* Track tables in EXCEPT and INTERSECT queries ([#239](https://github.com/pganalyze/pg_query/pull/239))
* Get filter_columns working with UNION/EXCEPT/INTERSECT ([#240](https://github.com/pganalyze/pg_query/pull/240))
* Update google-protobuf to address CVE scanner complaints
  - Note that none of the CVEs apply to pg_query, but this avoids unnecessary errors when
    the google-protobuf dependency is pulled in


## 2.1.2     2021-11-12

* Find tables in using clause of delete statement ([#234](https://github.com/pganalyze/pg_query/pull/234))
* Find tables in case statements ([#235](https://github.com/pganalyze/pg_query/pull/235))
* Correctly find nested tables in a subselect in a join condition ([#233](https://github.com/pganalyze/pg_query/pull/233))
* Mark Postgres methods as visibility hidden, to avoid bloating dynamic symbol table ([#232](https://github.com/pganalyze/pg_query/pull/232))
  - This is required on ELF platforms (i.e. Linux, etc) to avoid including all global
    symbols in the shared library's symbol table, bloating the size, and causing
    potential conflicts with other C libraries using the same symbol names.


## 2.1.1     2021-10-13

* Update to libpg_query 13-2.1.0 ([#230](https://github.com/pganalyze/pg_query/pull/230))
  - Normalize: add funcname error object
  - Normalize: Match GROUP BY against target list and re-use param refs
  - PL/pgSQL: Setup namespace items for parameters, support RECORD types
    - This significantly improves parsing for PL/pgSQL functions, to the extent
      that most functions should now parse successfully
  - Normalize: Don't modify constants in TypeName typmods/arrayBounds fields
    - This matches how pg_stat_statement behaves, and avoids causing parsing
      errors on the normalized statement
  - Don't fail builds on systems that have strchrnul support (FreeBSD)
* Fix build on FreeBSD ([#222](https://github.com/pganalyze/pg_query/pull/222))
* Add workaround for Ruby garbage collection bug ([#227](https://github.com/pganalyze/pg_query/pull/227))
  - The Ruby interpreter has a bug in `String#concat` where the appended
    array may be garbage collected prematurely because the compiler
    optimized out a Ruby stack variable. We now call `to_ary` on the
    Protobuf object to ensure the array lands on the Ruby stack so the
    garbage collector sees it.
  - The real fix in the interpreter is described in
    https://bugs.ruby-lang.org/issues/18140#note-2, but most current Ruby
    interpreters won't have this fix for some time.
* Table/function extraction: Support subselects and LATERAL better ([#229](https://github.com/pganalyze/pg_query/pull/229))
  - This reworks the parsing logic so we don't ignore certain kinds of
    subselects.


## 2.1.0     2021-07-04

* Update to libpg_query 13-2.0.6
  - Update to Postgres 13.3 patch release
  - Normalize: Don't touch "GROUP BY 1" and "ORDER BY 1" expressions, keep original text 
  - Fingerprint: Cache list item hashes to fingerprint complex queries faster
  - Deparser: Emit the RangeVar catalogname if present
  - Fix crash in pg_scan function when encountering backslash escapes
* Support extracting functions from a parsed query ([#147](https://github.com/pganalyze/pg_query/pull/147))
  - Adds new `functions`, `ddl_functions` and `call_functions` methods
  - Note that functions are identified by their name only, not their full type definition,
    since raw query parsetrees don't contain sufficient data to identify the types of
    arguments when functions are called
* Relax google-protobuf dependency ([#213](https://github.com/pganalyze/pg_query/pull/213))
* Update google-protobuf to 3.17.1 ([#212](https://github.com/pganalyze/pg_query/pull/212))
  - google-protobuf 3.15.x has a bug that causes a seg fault in Ruby under
    certain conditions (https://github.com/protocolbuffers/protobuf/pull/8639). Use
    google-protobuf 3.17.1 instead.
* Use Protobuf definition for determining JSON field names
  - Note you may see a breaking change if you were using `PgQuery::ParseResult.encode_json`
    to map the protobuf result to JSON, since this now respects the intended JSON names
    from the Proto3 definition (instead of the differently formatted Protobuf field names)
* Rakefile: Fix "rake clean" by using CLEAN.include instead of CLEAN.<<
* Find tables inside COALESCE/MIN/MAX functions, UPDATE FROM list
* Extconf: Add library include path using $INCFLAGS, list it first
  - This ensures any system installed libpg_query gets considered after
    the bundled libpg_query, avoiding errors where the wrong header files
    are used.


## 2.0.3     2021-04-05

* Update to libpg_query 13-2.0.4
  - Normalize: Fix handling of two subsequent DefElem elements (avoids crash)
  - Deparser: Fix crash in CopyStmt with HEADER or FREEZE inside WITH parens


## 2.0.2     2021-03-31

* `COALESCE` arguments are now included in `#filter_columns`
* Improve error message for protobuf parse failures
* Extconf: Fix object path regexp
  - This accidentally replaced `.c` in the wrong parts of the path in some cases,
    causing build failures
* Update to libpg_query 13-2.0.2
  - Fix ARM builds: Avoid dependency on cpuid.h header
  - Simplify deparser of TableLikeClause
  - Fix asprintf warnings by ensuring _GNU_SOURCE is set early enough


## 2.0.1     2021-03-18

* Fix gemspec to correctly reference include files
  - This would have shown as a build failure when using the published `2.0.0` gem


## 2.0.0     2021-03-18

* Update to PostgreSQL 13 parser
* Update to libpg_query v2, and new Protobuf-based format
  * WARNING: This is a breaking change if you are directly interacting with the
    parsetree (helpers like `table` and such still work the same way)
* Use actual Ruby classes for parser result, instead of decoded JSON
  * This is essentialy to enable easy and fast two-way communication with
    the C library, and as a bonus makes for a better interaction on the Ruby
    side, as we are handling actual objects instead of hashes and arrays.
* Use new deparser maintained directly in libpg_query
  * This replaces the complete Ruby deparser with a new, more complete deparser
    that is directly maintained in libpg_query. Further deparser improvements
    should be directly contributed to [libpg_query]
* Tables helper: Return more details through `#tables_with_details` method
  * This is renamed from the previously badly named `#tables_with_types`
    method. Note that this change should not affect the output of the
    primary `tables` helper.
* Replace on-demand libpg_query source download with bundled source code
  * Its unnecessary to download the source on-demand, and makes this more
    complex than it needs to be. Instead, introduce a new "update_source" rake
    task that can be called to refresh the source for a specified revision.
* Re-implement smart truncation without requiring a special node type
  * This ensures the `#truncate` method works with the new deparser, without
    the C level code needing to know about it. We may add it in the C library
    in the future for edge cases that can't be covered by this slightly
    hack-ish approach, but for now this avoids unnecessary C library
    deparser modifications with non-standard node types.
* Update Ruby fingerprinting to new fingerprint format and XXH3 hash
  * Note that its recommended to use `PgQuery.fingerprint` for performance
    reasons, but when the tree has been modified, it can be convenient to
    run a Ruby-side fingerprint instead of the C-based one that is faster.


## 1.3.0     2020-12-28

* Incorporate newer libpg_query updates in 10-1.0.3 and 10-1.0.4
  * Adds support for running on ARM
  * Fixes an asprintf warning during builds
  * Updates to newer Postgres 10 patch release (10.15)
* Deparsing improvements by [@emin100]
  * Add support for additional DROP statements ([#147](https://github.com/pganalyze/pg_query/pull/147))
  * Fix `CREATE TABLE AS` - Support without `TEMP`, Add `ON COMMIT` ([#149](https://github.com/pganalyze/pg_query/pull/149))
  * Empty target list support ([#156](https://github.com/pganalyze/pg_query/pull/156))
  * `UNION` parentheses ([#158](https://github.com/pganalyze/pg_query/pull/158))
  * `OVERLAY` keyword function ([#161](https://github.com/pganalyze/pg_query/pull/161))
  * Array indirection ([#162](https://github.com/pganalyze/pg_query/pull/162))
  * `ARRAY` functions ([#163](https://github.com/pganalyze/pg_query/pull/163))
  * Correctly handle column names that need escaping in `INSERT` and `UPDATE` statements ([#164](https://github.com/pganalyze/pg_query/pull/164))
  * `INSERT INTO ON CONFLICT` ([#166](https://github.com/pganalyze/pg_query/pull/166))
  * `LATERAL JOIN` ([#168](https://github.com/pganalyze/pg_query/pull/168))
  * `UPDATE FROM` clause ([#170](https://github.com/pganalyze/pg_query/pull/170))
  * `SELECT` aggregate `FILTER` ([#175](https://github.com/pganalyze/pg_query/pull/175))
  * `INTERSECT` operator ([#176](https://github.com/pganalyze/pg_query/pull/176))
* Deparsing: Improve handling of boolean type casts [@himanshu-pro] & [@emin100]
* `tables` method: Find tables in the subquery of `CREATE TABLE AS` ([#172](https://github.com/pganalyze/pg_query/pull/172)) [@Tassosb]
* Support Ruby 3.0, verify SHA256 checksum of downloaded libpg_query ([#178](https://github.com/pganalyze/pg_query/pull/178)) [@stanhu]
  * Verify SHA256 checksum to guard against any malicious attempts to change the archive
  * Use `URI.open` to fix Ruby 3.0 support


## 1.2.0     2019-11-10

* Reduce escaped keywords to Postgres-specific keywords, and ignore unreserved keywords
  * This matches the behaviour of Postgres' quote_identifier function, and avoids problems
    when doing text comparisons with output involving that function
  * Note that this will lead to different output than in earlier pg_query versions,
    in some cases


## 1.1.1     2019-11-10

* Deparsing improvements by [@emin100]
  * Deparse `ILIKE`, `COLLATE` and `DISCARD` ([#133](https://github.com/pganalyze/pg_query/pull/133))
  * `CREATE CAST` ([#136](https://github.com/pganalyze/pg_query/pull/136))
  * `CREATE SCHEMA` ([#136](https://github.com/pganalyze/pg_query/pull/136))
  * `UNION`, `UNION ALL` and `EXCEPT` in `SELECT` queries ([#136](https://github.com/pganalyze/pg_query/pull/136))
  * `CREATE DOMAIN` ([#145](https://github.com/pganalyze/pg_query/pull/145))
  * Subquery indirection ([#157](https://github.com/pganalyze/pg_query/pull/157))
  * Fix Type Cast Parentheses Problem ([#152](https://github.com/pganalyze/pg_query/pull/152))
  * `SELECT INTO` ([#151](https://github.com/pganalyze/pg_query/pull/151))
  * `SET DEFAULT` in `INSERT INTO` ([#154](https://github.com/pganalyze/pg_query/pull/154))
  * `REVOKE` ([#155](https://github.com/pganalyze/pg_query/pull/155))
  * `PREPARE` and `EXECUTE` ([#148](https://github.com/pganalyze/pg_query/pull/148))
  * `INSERT INTO ... RETURNING` ([#153](https://github.com/pganalyze/pg_query/pull/153))
  * Fix Alter .. `RENAME SQL` ([#146](https://github.com/pganalyze/pg_query/pull/146))
* Deparsing improvements by [@herwinw]
  * Fix subquery in `COPY` in deparse ([#112](https://github.com/pganalyze/pg_query/pull/112))
  * Function call indirection ([#116](https://github.com/pganalyze/pg_query/pull/116))
  * Function without parameters ([#117](https://github.com/pganalyze/pg_query/pull/117))
  * `CREATE AGGREGATE`
  * `CREATE OPERATOR`
  * `CREATE TYPE`
  * `GRANT` statements
  * `DROP SCHEMA`
* Deparsing improvements by [@akiellor]
  * Named window functions ([#150](https://github.com/pganalyze/pg_query/pull/150))
* Deparsing improvements by [@himanshu]
  * Arguments in custom types ([#143](https://github.com/pganalyze/pg_query/pull/143))
  * Use "double precision" instead of "double" type name ([#139](https://github.com/pganalyze/pg_query/pull/139))
* Use explicit -z flag to support OpenBSD tar ([#134](https://github.com/pganalyze/pg_query/pull/134)) [@sirn]
* Add Ruby 2.6 to Travis tests
* Escape identifiers in more cases, if necessary


## 1.1.0     2018-10-04

* Deparsing improvements by [@herwinw]
  * Add `NULLS FIRST`/`LAST` to `ORDER BY` [#95](https://github.com/pganalyze/pg_query/pull/95)
  * `VACUUM` [#97](https://github.com/pganalyze/pg_query/pull/97)
  * `UPDATE` with multiple columns [#99](https://github.com/pganalyze/pg_query/pull/99)
  * `DISTINCT ON` [#101](https://github.com/pganalyze/pg_query/pull/101)
  * `CREATE TABLE AS` [#102](https://github.com/pganalyze/pg_query/pull/102)
  * SQL value functions [#103](https://github.com/pganalyze/pg_query/pull/103)
  * `LOCK` [#105](https://github.com/pganalyze/pg_query/pull/105)
  * `EXPLAIN` [#107](https://github.com/pganalyze/pg_query/pull/107)
  * `COPY` [#108](https://github.com/pganalyze/pg_query/pull/108)
  * `DO` [#109](https://github.com/pganalyze/pg_query/pull/109)
* Ignore pg_query.so in git checkout [#110](https://github.com/pganalyze/pg_query/pull/110) [@herwinw]
* Prefer `__dir__` over `File.dirname(__FILE__)` [#110](https://github.com/pganalyze/pg_query/pull/104) [@herwinw]


## 1.0.2     2018-04-11

* Deparsing improvements
  * `SELECT DISTINCT` clause [#77](https://github.com/pganalyze/pg_query/pull/77) [@Papierkorb]
  * "`CASE expr WHEN ... END`" clause [#78](https://github.com/pganalyze/pg_query/pull/78) [@Papierkorb]
  * `LEFT`/`RIGHT`/`FULL`/`NATURAL JOIN` [#79](https://github.com/pganalyze/pg_query/pull/79) [@Papierkorb]
  * `SELECT` that includes schema name [#80](https://github.com/pganalyze/pg_query/pull/80) [@jcsjcs]


## 1.0.1     2018-02-02

* Parse CTEs and nested selects in INSERT/UPDATE [#76](https://github.com/pganalyze/pg_query/pull/76) [@jcoleman]
* Drop explicit json dependency [#74](https://github.com/pganalyze/pg_query/pull/74) [@yuki24]


## 1.0.0     2017-10-31

* IMPORTANT: Major version bump to indicate backwards incompatible parse tree change!
* Update to Postgres 10 parser and fingerprint version 2
  - This is a backwards-incompatible change in parser output format, although it should
    be relatively easy to update most programs. This can't be avoided since Postgres
    does not guarantee parse trees stay the same across versions


## 0.13.5    2017-10-26

* Update to libpg_query 9.5-1.7.1
  - Allow "`$1 FROM $2`" to be parsed (new with pg_stat_statements in Postgres 10)


## 0.13.4    2017-10-20

* Update to libpg_query 9.5-1.7.0
  - Fixes compilation old gcc before 4.6.0 [#73](https://github.com/pganalyze/pg_query/issues/73)


## 0.13.3    2017-09-04

* Fix table detection for SELECTs that have sub-SELECTs without `FROM` clause [#69](https://github.com/pganalyze/pg_query/issues/69)


## 0.13.2    2017-08-10

* Support table detection in sub-SELECTs in `JOIN`s [#68](https://github.com/pganalyze/pg_query/pull/65) [@seanmdick]
* Legacy ".parsetree" helper: Fix "Between" and "In" operator does not have "AEXPR" [#66](https://github.com/pganalyze/pg_query/issues/66)
  * For new applications please use ".tree" method which uses the native structure
    returned from libpg_query which resembles Postgres node names more closely


## 0.13.1    2017-08-03

* Fix regression in 0.13.1 that broke ".tables" logic for `COPY` statements that
  don't have a target table (i.e. are reading out data vs copying in)


## 0.13.0    2017-07-30

* Introduce split between SELECT/DML/DDL for tables method [#65](https://github.com/pganalyze/pg_query/pull/65) [@chrisfrommann]
  * Backwards compatible, use the new select_tables/dml_tables/ddl_tables to
    access the categorized table references
* Update libpg_query to 9.5-1.6.2
  * Update to Fingerprinting Version 1.3
    * Attributes to be ignored:
      * RangeVar.relname (if node also has RangeVar.relpersistence = "t")
    * Special cases: List nodes where parent field name is valuesLists
      * Follow same logic described for fromClause/targetList/cols/rexpr


## 0.12.1    2017-07-29

* Update libpg_query to 9.5-1.6.1
  * Update to Fingerprinting Version 1.2
    * Ignore portalname in DeclareCursorStmt, FetchStmt and ClosePortalStmt


## 0.12.0    2017-07-29

* Update libpg_query to 9.5-1.6.0
  * BREAKING CHANGE in PgQuery.normalize(..) output
  * This matches the change in the upcoming Postgres 10, and makes it easier to
    migrate applications to the new normalization format using $1..$N instead of ?


## 0.11.5    2017-07-09

* Deparse coldeflist [#64](https://github.com/pganalyze/pg_query/pull/64) [@jcsjcs]
* Use Integer class for checking integer instead of Fixnum [#62](https://github.com/pganalyze/pg_query/pull/62) [@makimoto]


## 0.11.4    2017-01-18

* Compatibility with Ruby 2.4 [#59](https://github.com/pganalyze/pg_query/pull/59) [@merqlove]
* Deparse varchar and numeric casts without arguments [#61](https://github.com/pganalyze/pg_query/pull/61) [@jcsjcs]


## 0.11.3    2016-12-06

* Update to newest libpg_query version (9.5-1.4.2)
  * Cut off fingerprints at 100 nodes deep to avoid excessive runtimes/memory
  * Fix warning on Linux due to missing asprintf include
* Improved deparsing [@jcsjcs]
  * Float [#54](https://github.com/pganalyze/pg_query/pull/54)
  * `BETWEEN` [#55](https://github.com/pganalyze/pg_query/pull/55)
  * `NULLIF` [#56](https://github.com/pganalyze/pg_query/pull/56)
  * `SELECT NULL` and BooleanTest [#57](https://github.com/pganalyze/pg_query/pull/57)
* Fix build on BSD systems [#58](https://github.com/pganalyze/pg_query/pull/58) [@myfreeweb]


## 0.11.2    2016-06-27

* Update to newest libpg_query version (9.5-1.4.1)
  * This release makes sure we work correctly in threaded environments


## 0.11.1    2016-06-26

* Updated fingerprinting logic to version 1.1
  * Fixes an issue with UpdateStmt target lists being ignored
* Update to newest libpg_query version (9.5-1.4.0)


## 0.11.0    2016-06-22

* Improved table name analysis (`#tables` method)
  * Don't include CTE names, make them accessible as `#cte_names` instead [#52](https://github.com/pganalyze/pg_query/issues/52)
  * Include table names in target list sub selects [#38](https://github.com/pganalyze/pg_query/issues/38)
  * Add support for `ORDER`/`GROUP BY`, `HAVING`, and booleans in `WHERE` [#53](https://github.com/pganalyze/pg_query/pull/53) [@jcoleman]
  * Fix parsing of `DROP TYPE` statements


## 0.10.0    2016-05-31

* Based on PostgreSQL 9.5.3
* Use LLVM extracted parser for significantly improved build times (via libpg_query)
* Deparsing Improvements
  * `SET` statements [#48](https://github.com/pganalyze/pg_query/pull/48) [@Winslett]
  * `LIKE`/`NOT LIKE` [#49](https://github.com/pganalyze/pg_query/pull/49) [@Winslett]
  * `CREATE FUNCTION` improvements [#50](https://github.com/pganalyze/pg_query/pull/50) [@Winslett]


## 0.9.2    2016-05-03

* Fix issue with A_CONST string values in `.parsetree` compatibility layer (Fixes [#47](https://github.com/pganalyze/pg_query/issues/47))


## 0.9.1    2016-04-20

* Add support for Ruby 1.9 (Fixes [#44](https://github.com/pganalyze/pg_query/issues/44))


## 0.9.0    2016-04-17

* Based on PostgreSQL 9.5.2
* NOTE: Output format for the parse tree has changed (backwards incompatible!),
        it is recommended you extensively test any direct reading/modification of
        the tree data in your own code
  * You can use the `.parsetree` translator method to ease the transition, note
    however that there are still a few incompatible changes
* New `.fingerprint` method (backwards incompatible as well), see https://github.com/lfittl/libpg_query/wiki/Fingerprinting
* Removes PostgreSQL source and tarball after build process has finished, to reduce
  diskspace requirements of the installed gem


## 0.8.0    2016-03-06

* Use fixed git version for libpg_query (PostgreSQL 9.4 based)
* NOTE: 0.8 will be the last series with the initial parse tree format, 0.9 will
        introduce a newer, more stable, but backwards incompatible parse tree format


## 0.7.2    2015-12-20

* Deparsing
  * Quote all column refs [#40](https://github.com/pganalyze/pg_query/pull/40) [@avinoamr]
  * Quote all range vars [#43](https://github.com/pganalyze/pg_query/pull/43) [@avinoamr]
  * Support for `COUNT(DISTINCT ...)` [#42](https://github.com/pganalyze/pg_query/pull/42) [@avinoamr]


## 0.7.1    2015-11-17

* Abstracted parser access into libpg_query [#24](https://github.com/pganalyze/pg_query/pull/35)
* libpg_query
  * Use UTF-8 encoding for parsing [#4](https://github.com/lfittl/libpg_query/pull/4) [@zhm]
  * Add type to A_CONST nodes[#5](https://github.com/lfittl/libpg_query/pull/5) [@zhm]


## 0.7.0    2015-10-17

* Restructure build process to use upstream tarballs [#35](https://github.com/pganalyze/pg_query/pull/35)
  * Avoid bison/flex dependency to make deployment easier [#31](https://github.com/pganalyze/pg_query/issues/31)
* Solve issues with deployments to Heroku [#32](https://github.com/pganalyze/pg_query/issues/32)
* Deparsing
  * `HAVING` and `FOR UPDATE` [#36](https://github.com/pganalyze/pg_query/pull/36) [@JackDanger]


## 0.6.4    2015-10-01

* Deparsing
  * Constraints & Interval Types [#28](https://github.com/pganalyze/pg_query/pull/28) [@JackDanger]
  * Cross joins [#29](https://github.com/pganalyze/pg_query/pull/29) [@mme]
  * `ALTER TABLE` [#30](https://github.com/pganalyze/pg_query/pull/30) [@JackDanger]
  * `LIMIT and OFFSET` [#33](https://github.com/pganalyze/pg_query/pull/33) [@jcsjcs]


## 0.6.3    2015-08-20

* Deparsing
  * `COUNT(*)` [@JackDanger]
  * Window clauses [Chris Martin]
  * `CREATE TABLE`/`VIEW/FUNCTION` [@JackDanger]
* Return exact location for parser errors [@JackDanger]


## 0.6.2    2015-08-06

* Speed up gem install by not generating rdoc/ri for the Postgres source


## 0.6.1    2015-08-06

* Deparsing: Support `WITH` clauses in `INSERT`/`UPDATE`/`DELETE` [@JackDanger]
* Make sure gemspec includes all necessary files


## 0.6.0    2015-08-05

* Deparsing (experimental)
  * Turns parse trees into SQL again
  * New truncate method to smartly truncate based on less important query parts
  * Thanks to [@mme] & [@JackDanger] for their contributions
* Restructure extension C code
* Add table/filter columns support for CTEs
* Extract views as tables from `CREATE`/`REFRESH VIEW`
* Refactor code using generic treewalker
* fingerprint: Normalize `IN` lists
* param_refs: Fix length attribute in result


## 0.5.0    2015-03-26

* Query fingerprinting
* Filter columns (aka columns referenced in a query's `WHERE` clause)
* Parameter references: Returns all `$1`/`$2`/etc like references in the query with their location
* Remove dependency on active_support


## 0.4.1    2014-12-18

* Fix compilation of C extension
* Fix gemspec


## 0.4.0    2014-12-18

* Speed up build time by only building necessary objects
* PostgreSQL 9.4 parser


See git commit log for previous releases.

[libpg_query]: https://github.com/pganalyze/libpg_query
[@emin100]: https://github.com/emin100
[@akiellor]: https://github.com/akiellor
[@himanshu-pro]: https://github.com/himanshu-pro
[@himanshu]: https://github.com/himanshu
[@Tassosb]: https://github.com/Tassosb
[@herwinw]: https://github.com/herwinw
[@stanhu]: https://github.com/stanhu
[@Papierkorb]: https://github.com/Papierkorb
[@jcsjcs]: https://github.com/jcsjcs
[@jcoleman]: https://github.com/jcoleman
[@yuki24]: https://github.com/yuki24
[@seanmdick]: https://github.com/seanmdick
[@chrisfrommann]: https://github.com/chrisfrommann
[@makimoto]: https://github.com/makimoto
[@merqlove]: https://github.com/merqlove
[@myfreeweb]: https://github.com/myfreeweb
[@Winslett]: https://github.com/Winslett
[@avinoamr]: https://github.com/avinoamr
[@zhm]: https://github.com/zhm
[@mme]: https://github.com/mme
[@JackDanger]: https://github.com/JackDanger
[Chris Martin]: https://github.com/cmrtn
[@sirn]: https://github.com/sirn
