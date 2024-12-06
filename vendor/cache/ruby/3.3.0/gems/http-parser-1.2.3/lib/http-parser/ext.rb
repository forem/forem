# frozen_string_literal: true

require 'ffi'
require 'ffi-compiler/loader'

module HttpParser
    extend FFI::Library
    ffi_lib FFI::Compiler::Loader.find('http-parser-ext')
end
