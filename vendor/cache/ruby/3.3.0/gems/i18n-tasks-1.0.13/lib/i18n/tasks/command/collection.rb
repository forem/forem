# frozen_string_literal: true

require 'i18n/tasks/command/dsl'
require 'i18n/tasks/command/options/common'
require 'i18n/tasks/command/options/locales'
require 'i18n/tasks/command/options/data'

module I18n::Tasks
  module Command
    module Collection
      def self.included(base)
        base.module_eval do
          include Command::DSL
          include Command::Options::Common
          include Command::Options::Locales
          include Command::Options::Data
        end
      end
    end
  end
end
