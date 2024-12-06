# frozen_string_literal: true

require "mime/type"
require "fileutils"

gem "minitest"
require "minitest/focus"
require "minitest/hooks"

ENV["RUBY_MIME_TYPES_LAZY_LOAD"] = "yes"
