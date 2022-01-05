require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'

begin
  require 'rails/engine'
  require 'acts_as_taggable_on/engine'
  rescue LoadError

end

require 'digest/sha1'

module ActsAsTaggableOn
  extend ActiveSupport::Autoload

  autoload :Tag
  autoload :TagList
  autoload :GenericParser
  autoload :DefaultParser
  autoload :Taggable
  autoload :Tagger
  autoload :Tagging
  autoload :TagsHelper
  autoload :VERSION

  autoload_under 'taggable' do
    autoload :Cache
    autoload :Collection
    autoload :Core
    autoload :Dirty
    autoload :Ownership
    autoload :Related
    autoload :TagListType
  end

  autoload :Utils
  autoload :Compatibility


  class DuplicateTagError < StandardError
  end

  def self.setup
    @configuration ||= Configuration.new
    yield @configuration if block_given?
  end

  def self.method_missing(method_name, *args, &block)
    @configuration.respond_to?(method_name) ?
        @configuration.send(method_name, *args, &block) : super
  end

  def self.respond_to?(method_name, include_private=false)
    @configuration.respond_to? method_name
  end

  def self.glue
    setting = @configuration.delimiter
    delimiter = setting.kind_of?(Array) ? setting[0] : setting
    delimiter.end_with?(' ') ? delimiter : "#{delimiter} "
  end

  class Configuration
    attr_accessor :force_lowercase, :force_parameterize,
                  :remove_unused_tags, :default_parser,
                  :tags_counter, :tags_table,
                  :taggings_table
    attr_reader :delimiter, :strict_case_match

    def initialize
      @delimiter = ','
      @force_lowercase = false
      @force_parameterize = false
      @strict_case_match = false
      @remove_unused_tags = false
      @tags_counter = true
      @default_parser = DefaultParser
      @force_binary_collation = false
      @tags_table = :tags
      @taggings_table = :taggings
    end

    def strict_case_match=(force_cs)
      @strict_case_match = force_cs unless @force_binary_collation
    end

    def delimiter=(string)
      ActiveRecord::Base.logger.warn <<WARNING
ActsAsTaggableOn.delimiter is deprecated \
and will be removed from v4.0+, use  \
a ActsAsTaggableOn.default_parser instead
WARNING
      @delimiter = string
    end

    def force_binary_collation=(force_bin)
      if Utils.using_mysql?
        if force_bin
          Configuration.apply_binary_collation(true)
          @force_binary_collation = true
          @strict_case_match = true
        else
          Configuration.apply_binary_collation(false)
          @force_binary_collation = false
        end
      end
    end

    def self.apply_binary_collation(bincoll)
      if Utils.using_mysql?
        coll = 'utf8_general_ci'
        coll = 'utf8_bin' if bincoll
        begin
          ActiveRecord::Migration.execute("ALTER TABLE #{Tag.table_name} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE #{coll};")
        rescue Exception => e
          puts "Trapping #{e.class}: collation parameter ignored while migrating for the first time."
        end
      end
    end

  end

  setup
end

ActiveSupport.on_load(:active_record) do
  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger
end
ActiveSupport.on_load(:action_view) do
  include ActsAsTaggableOn::TagsHelper
end
