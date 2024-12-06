# frozen_string_literal: true

# Load experimental, proposed etc. Ruby features

require "ruby-next/language/rewriters/proposed/method_reference"
RubyNext::Language.rewriters << RubyNext::Language::Rewriters::MethodReference

require "ruby-next/language/rewriters/proposed/bind_vars_pattern"
RubyNext::Language.rewriters << RubyNext::Language::Rewriters::BindVarsPattern
