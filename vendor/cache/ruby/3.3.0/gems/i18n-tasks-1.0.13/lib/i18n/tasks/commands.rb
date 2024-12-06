# frozen_string_literal: true

require 'i18n/tasks/command/dsl'
require 'i18n/tasks/command/collection'
require 'i18n/tasks/command/commands/health'
require 'i18n/tasks/command/commands/missing'
require 'i18n/tasks/command/commands/usages'
require 'i18n/tasks/command/commands/interpolations'
require 'i18n/tasks/command/commands/eq_base'
require 'i18n/tasks/command/commands/data'
require 'i18n/tasks/command/commands/tree'
require 'i18n/tasks/command/commands/meta'
require 'i18n/tasks/command/commander'

module I18n::Tasks
  class Commands < Command::Commander
    include Command::DSL
    include Command::Commands::Health
    include Command::Commands::Missing
    include Command::Commands::Usages
    include Command::Commands::Interpolations
    include Command::Commands::EqBase
    include Command::Commands::Data
    include Command::Commands::Tree
    include Command::Commands::Meta

    require 'highline/import'
  end
end
