# frozen_string_literal: true

# Require current parser without warnings
save_verbose, $VERBOSE = $VERBOSE, nil
require "parser/current"
$VERBOSE = save_verbose

require "unparser"

# For backward compatibility with older Unparser
if RubyNext::Language::Builder.respond_to?(:emit_kwargs=) && !defined?(Unparser::Emitter::Kwargs)
  RubyNext::Language::Builder.emit_kwargs = false
end
