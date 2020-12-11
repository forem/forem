#!/bin/bash
# set -x

# This list is from https://charlie.bz/blog/things-that-clear-rubys-method-cache

IGNORE_FILE=/tmp/cache_busters_ignore
COMMENT_LINE_RE="^(\w|\/)+\.rb: +#"

cat script/ignores | grep -v "^$" | ruby -ne 'puts $_.split(/\s+###/)[0]' > $IGNORE_FILE

egrep 'def [a-z]*\..*' -R lib | grep -v "def self" | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep undef -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep alias_method -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep remove_method -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep const_set -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep remove_const -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
egrep '\bextend\b' -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep 'Class.new' -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep private_constant -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep public_constant -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep "Marshal.load" -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"
grep "OpenStruct.new" -R lib | grep -v -f $IGNORE_FILE | egrep -v "$COMMENT_LINE_RE"

