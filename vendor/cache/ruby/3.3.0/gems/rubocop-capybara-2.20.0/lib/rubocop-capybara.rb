# frozen_string_literal: true

require 'pathname'
require 'yaml'

require 'rubocop'

require_relative 'rubocop/cop/capybara/mixin/capybara_help'
require_relative 'rubocop/cop/capybara/mixin/css_attributes_parser'
require_relative 'rubocop/cop/capybara/mixin/css_selector'

require_relative 'rubocop/cop/capybara_cops'

project_root = File.join(__dir__, '..')
RuboCop::ConfigLoader.inject_defaults!(project_root)
obsoletion = File.join(project_root, 'config', 'obsoletion.yml')
RuboCop::ConfigObsoletion.files << obsoletion if File.exist?(obsoletion)

RuboCop::Cop::Style::TrailingCommaInArguments.singleton_class.prepend(
  Module.new do
    def autocorrect_incompatible_with
      super.push(RuboCop::Cop::Capybara::CurrentPathExpectation)
    end
  end
)
