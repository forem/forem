# frozen_string_literal: true

require 'pathname'
require 'yaml'

require 'rubocop'

require_relative 'rubocop/factory_bot/factory_bot'
require_relative 'rubocop/factory_bot/language'

require_relative 'rubocop/cop/factory_bot/mixin/configurable_explicit_only'

require_relative 'rubocop/cop/factory_bot_cops'

project_root = File.join(__dir__, '..')
RuboCop::ConfigLoader.inject_defaults!(project_root)
obsoletion = File.join(project_root, 'config', 'obsoletion.yml')
RuboCop::ConfigObsoletion.files << obsoletion if File.exist?(obsoletion)
