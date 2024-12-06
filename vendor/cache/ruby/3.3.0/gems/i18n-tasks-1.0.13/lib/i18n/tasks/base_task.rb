# frozen_string_literal: true

require 'i18n/tasks/command_error'
require 'i18n/tasks/split_key'
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/logging'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/references'
require 'i18n/tasks/html_keys'
require 'i18n/tasks/used_keys'
require 'i18n/tasks/ignore_keys'
require 'i18n/tasks/missing_keys'
require 'i18n/tasks/interpolations'
require 'i18n/tasks/unused_keys'
require 'i18n/tasks/translation'
require 'i18n/tasks/locale_pathname'
require 'i18n/tasks/locale_list'
require 'i18n/tasks/string_interpolation'
require 'i18n/tasks/data'
require 'i18n/tasks/configuration'
require 'i18n/tasks/stats'

module I18n
  module Tasks
    class BaseTask
      include SplitKey
      include KeyPatternMatching
      include PluralKeys
      include References
      include HtmlKeys
      include UsedKeys
      include IgnoreKeys
      include MissingKeys
      include Interpolations
      include UnusedKeys
      include Translation
      include Logging
      include Configuration
      include Data
      include Stats

      def initialize(config_file: nil, **config)
        @config_override = config_file
        self.config = config || {}
      end

      def inspect
        "#{self.class.name}#{config_for_inspect}"
      end
    end
  end
end
