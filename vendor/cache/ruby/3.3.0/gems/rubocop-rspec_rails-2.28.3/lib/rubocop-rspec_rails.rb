# frozen_string_literal: true

require 'pathname'
require 'yaml'

require 'rubocop'

require 'rubocop/rspec/language/node_pattern'

require 'rubocop/rspec/language'

require_relative 'rubocop/rspec_rails/version'

require 'rubocop/cop/rspec/base'
require_relative 'rubocop/cop/rspec_rails_cops'

project_root = File.join(__dir__, '..')
RuboCop::ConfigLoader.inject_defaults!(project_root)

# FIXME: This is a workaround for the following issue:
# https://github.com/rubocop/rubocop-rspec_rails/issues/8
module RuboCop
  module Cop
    class Registry # rubocop:disable Style/Documentation
      prepend(Module.new do
        def qualified_cop_name(name, path, warn: true)
          return super unless name == 'RSpec/Rails/HttpStatus'

          badge = Badge.parse(name)
          resolve_badge(badge, qualify_badge(badge).first, path)
        end
      end)
    end
  end
end
