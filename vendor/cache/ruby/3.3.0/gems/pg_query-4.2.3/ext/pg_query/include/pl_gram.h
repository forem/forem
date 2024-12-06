/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     IDENT = 258,
     UIDENT = 259,
     FCONST = 260,
     SCONST = 261,
     USCONST = 262,
     BCONST = 263,
     XCONST = 264,
     Op = 265,
     ICONST = 266,
     PARAM = 267,
     TYPECAST = 268,
     DOT_DOT = 269,
     COLON_EQUALS = 270,
     EQUALS_GREATER = 271,
     LESS_EQUALS = 272,
     GREATER_EQUALS = 273,
     NOT_EQUALS = 274,
     SQL_COMMENT = 275,
     C_COMMENT = 276,
     T_WORD = 277,
     T_CWORD = 278,
     T_DATUM = 279,
     LESS_LESS = 280,
     GREATER_GREATER = 281,
     K_ABSOLUTE = 282,
     K_ALIAS = 283,
     K_ALL = 284,
     K_AND = 285,
     K_ARRAY = 286,
     K_ASSERT = 287,
     K_BACKWARD = 288,
     K_BEGIN = 289,
     K_BY = 290,
     K_CALL = 291,
     K_CASE = 292,
     K_CHAIN = 293,
     K_CLOSE = 294,
     K_COLLATE = 295,
     K_COLUMN = 296,
     K_COLUMN_NAME = 297,
     K_COMMIT = 298,
     K_CONSTANT = 299,
     K_CONSTRAINT = 300,
     K_CONSTRAINT_NAME = 301,
     K_CONTINUE = 302,
     K_CURRENT = 303,
     K_CURSOR = 304,
     K_DATATYPE = 305,
     K_DEBUG = 306,
     K_DECLARE = 307,
     K_DEFAULT = 308,
     K_DETAIL = 309,
     K_DIAGNOSTICS = 310,
     K_DO = 311,
     K_DUMP = 312,
     K_ELSE = 313,
     K_ELSIF = 314,
     K_END = 315,
     K_ERRCODE = 316,
     K_ERROR = 317,
     K_EXCEPTION = 318,
     K_EXECUTE = 319,
     K_EXIT = 320,
     K_FETCH = 321,
     K_FIRST = 322,
     K_FOR = 323,
     K_FOREACH = 324,
     K_FORWARD = 325,
     K_FROM = 326,
     K_GET = 327,
     K_HINT = 328,
     K_IF = 329,
     K_IMPORT = 330,
     K_IN = 331,
     K_INFO = 332,
     K_INSERT = 333,
     K_INTO = 334,
     K_IS = 335,
     K_LAST = 336,
     K_LOG = 337,
     K_LOOP = 338,
     K_MERGE = 339,
     K_MESSAGE = 340,
     K_MESSAGE_TEXT = 341,
     K_MOVE = 342,
     K_NEXT = 343,
     K_NO = 344,
     K_NOT = 345,
     K_NOTICE = 346,
     K_NULL = 347,
     K_OPEN = 348,
     K_OPTION = 349,
     K_OR = 350,
     K_PERFORM = 351,
     K_PG_CONTEXT = 352,
     K_PG_DATATYPE_NAME = 353,
     K_PG_EXCEPTION_CONTEXT = 354,
     K_PG_EXCEPTION_DETAIL = 355,
     K_PG_EXCEPTION_HINT = 356,
     K_PRINT_STRICT_PARAMS = 357,
     K_PRIOR = 358,
     K_QUERY = 359,
     K_RAISE = 360,
     K_RELATIVE = 361,
     K_RETURN = 362,
     K_RETURNED_SQLSTATE = 363,
     K_REVERSE = 364,
     K_ROLLBACK = 365,
     K_ROW_COUNT = 366,
     K_ROWTYPE = 367,
     K_SCHEMA = 368,
     K_SCHEMA_NAME = 369,
     K_SCROLL = 370,
     K_SLICE = 371,
     K_SQLSTATE = 372,
     K_STACKED = 373,
     K_STRICT = 374,
     K_TABLE = 375,
     K_TABLE_NAME = 376,
     K_THEN = 377,
     K_TO = 378,
     K_TYPE = 379,
     K_USE_COLUMN = 380,
     K_USE_VARIABLE = 381,
     K_USING = 382,
     K_VARIABLE_CONFLICT = 383,
     K_WARNING = 384,
     K_WHEN = 385,
     K_WHILE = 386
   };
#endif
/* Tokens.  */
#define IDENT 258
#define UIDENT 259
#define FCONST 260
#define SCONST 261
#define USCONST 262
#define BCONST 263
#define XCONST 264
#define Op 265
#define ICONST 266
#define PARAM 267
#define TYPECAST 268
#define DOT_DOT 269
#define COLON_EQUALS 270
#define EQUALS_GREATER 271
#define LESS_EQUALS 272
#define GREATER_EQUALS 273
#define NOT_EQUALS 274
#define SQL_COMMENT 275
#define C_COMMENT 276
#define T_WORD 277
#define T_CWORD 278
#define T_DATUM 279
#define LESS_LESS 280
#define GREATER_GREATER 281
#define K_ABSOLUTE 282
#define K_ALIAS 283
#define K_ALL 284
#define K_AND 285
#define K_ARRAY 286
#define K_ASSERT 287
#define K_BACKWARD 288
#define K_BEGIN 289
#define K_BY 290
#define K_CALL 291
#define K_CASE 292
#define K_CHAIN 293
#define K_CLOSE 294
#define K_COLLATE 295
#define K_COLUMN 296
#define K_COLUMN_NAME 297
#define K_COMMIT 298
#define K_CONSTANT 299
#define K_CONSTRAINT 300
#define K_CONSTRAINT_NAME 301
#define K_CONTINUE 302
#define K_CURRENT 303
#define K_CURSOR 304
#define K_DATATYPE 305
#define K_DEBUG 306
#define K_DECLARE 307
#define K_DEFAULT 308
#define K_DETAIL 309
#define K_DIAGNOSTICS 310
#define K_DO 311
#define K_DUMP 312
#define K_ELSE 313
#define K_ELSIF 314
#define K_END 315
#define K_ERRCODE 316
#define K_ERROR 317
#define K_EXCEPTION 318
#define K_EXECUTE 319
#define K_EXIT 320
#define K_FETCH 321
#define K_FIRST 322
#define K_FOR 323
#define K_FOREACH 324
#define K_FORWARD 325
#define K_FROM 326
#define K_GET 327
#define K_HINT 328
#define K_IF 329
#define K_IMPORT 330
#define K_IN 331
#define K_INFO 332
#define K_INSERT 333
#define K_INTO 334
#define K_IS 335
#define K_LAST 336
#define K_LOG 337
#define K_LOOP 338
#define K_MERGE 339
#define K_MESSAGE 340
#define K_MESSAGE_TEXT 341
#define K_MOVE 342
#define K_NEXT 343
#define K_NO 344
#define K_NOT 345
#define K_NOTICE 346
#define K_NULL 347
#define K_OPEN 348
#define K_OPTION 349
#define K_OR 350
#define K_PERFORM 351
#define K_PG_CONTEXT 352
#define K_PG_DATATYPE_NAME 353
#define K_PG_EXCEPTION_CONTEXT 354
#define K_PG_EXCEPTION_DETAIL 355
#define K_PG_EXCEPTION_HINT 356
#define K_PRINT_STRICT_PARAMS 357
#define K_PRIOR 358
#define K_QUERY 359
#define K_RAISE 360
#define K_RELATIVE 361
#define K_RETURN 362
#define K_RETURNED_SQLSTATE 363
#define K_REVERSE 364
#define K_ROLLBACK 365
#define K_ROW_COUNT 366
#define K_ROWTYPE 367
#define K_SCHEMA 368
#define K_SCHEMA_NAME 369
#define K_SCROLL 370
#define K_SLICE 371
#define K_SQLSTATE 372
#define K_STACKED 373
#define K_STRICT 374
#define K_TABLE 375
#define K_TABLE_NAME 376
#define K_THEN 377
#define K_TO 378
#define K_TYPE 379
#define K_USE_COLUMN 380
#define K_USE_VARIABLE 381
#define K_USING 382
#define K_VARIABLE_CONFLICT 383
#define K_WARNING 384
#define K_WHEN 385
#define K_WHILE 386




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 120 "pl_gram.y"
{
	core_YYSTYPE core_yystype;
	/* these fields must match core_YYSTYPE: */
	int			ival;
	char	   *str;
	const char *keyword;

	PLword		word;
	PLcword		cword;
	PLwdatum	wdatum;
	bool		boolean;
	Oid			oid;
	struct
	{
		char	   *name;
		int			lineno;
	}			varname;
	struct
	{
		char	   *name;
		int			lineno;
		PLpgSQL_datum *scalar;
		PLpgSQL_datum *row;
	}			forvariable;
	struct
	{
		char	   *label;
		int			n_initvars;
		int		   *initvarnos;
	}			declhdr;
	struct
	{
		List	   *stmts;
		char	   *end_label;
		int			end_label_location;
	}			loop_body;
	List	   *list;
	PLpgSQL_type *dtype;
	PLpgSQL_datum *datum;
	PLpgSQL_var	*var;
	PLpgSQL_expr *expr;
	PLpgSQL_stmt *stmt;
	PLpgSQL_condition *condition;
	PLpgSQL_exception *exception;
	PLpgSQL_exception_block	*exception_block;
	PLpgSQL_nsitem *nsitem;
	PLpgSQL_diag_item *diagitem;
	PLpgSQL_stmt_fetch *fetch;
	PLpgSQL_case_when *casewhen;
}
/* Line 1529 of yacc.c.  */
#line 362 "pl_gram.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern __thread  YYSTYPE plpgsql_yylval;

#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
} YYLTYPE;
# define yyltype YYLTYPE /* obsolescent; will be withdrawn */
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif

extern __thread  YYLTYPE plpgsql_yylloc;
