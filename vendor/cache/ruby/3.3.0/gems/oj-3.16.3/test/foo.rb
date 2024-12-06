#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'json'
require 'oj'
require 'oj/json'

Oj.mimic_JSON

JSON.parse("[]")
