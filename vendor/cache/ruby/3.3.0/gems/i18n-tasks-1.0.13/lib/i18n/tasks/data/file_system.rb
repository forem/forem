# frozen_string_literal: true

require 'i18n/tasks/data/file_system_base'
require 'i18n/tasks/data/adapter/json_adapter'
require 'i18n/tasks/data/adapter/yaml_adapter'

module I18n::Tasks
  module Data
    class FileSystem < FileSystemBase
      register_adapter :yaml, '*.yml', Adapter::YamlAdapter
      register_adapter :json, '*.json', Adapter::JsonAdapter
    end
  end
end
