require_relative 'ancestry/version'
require_relative 'ancestry/class_methods'
require_relative 'ancestry/instance_methods'
require_relative 'ancestry/exceptions'
require_relative 'ancestry/has_ancestry'
require_relative 'ancestry/materialized_path'
require_relative 'ancestry/materialized_path2'
require_relative 'ancestry/materialized_path_pg'

I18n.load_path += Dir[File.join(File.expand_path(File.dirname(__FILE__)),
                                 'ancestry', 'locales', '*.{rb,yml}').to_s]

module Ancestry
  @@default_update_strategy = :ruby
  @@default_ancestry_format = :materialized_path
  @@default_primary_key_format = '[0-9]+'

  # @!default_update_strategy
  #   @return [Symbol] the default strategy for updating ancestry
  #
  # The value changes the default way that ancestry is updated for associated records
  #
  #    :ruby (default and legacy value)
  #
  #        Child records will be loaded into memory and updated. callbacks will get called
  #        The callbacks of interest are those that cache values based upon the ancestry value
  #
  #    :sql (currently only valid in postgres)
  #
  #        Child records are updated in sql and callbacks will not get called.
  #        Associated records in memory will have the wrong ancestry value
  def self.default_update_strategy
    @@default_update_strategy
  end

  def self.default_update_strategy=(value)
    @@default_update_strategy = value
  end

  # @!default_ancestry_format
  #   @return [Symbol] the default strategy for updating ancestry
  #
  # The value changes the default way that ancestry is stored in the database
  #
  #    :materialized_path (default and legacy)
  #
  #        Ancestry is of the form null (for no ancestors) and 1/2/ for children
  #
  #    :materialized_path2 (preferred)
  #
  #        Ancestry is of the form '/' (for no ancestors) and '/1/2/' for children
  def self.default_ancestry_format
    @@default_ancestry_format
  end

  def self.default_ancestry_format=(value)
    @@default_ancestry_format = value
  end

  # @!default_primary_key_format
  #   @return [Symbol] the regular expression representing the primary key
  #
  # The value represents the way the id looks for validation
  #
  #    '[0-9]+' (default) for integer ids
  #    '[-A-Fa-f0-9]{36}'    for uuids (though you can find other regular expressions)
  def self.default_primary_key_format
    @@default_primary_key_format
  end

  def self.default_primary_key_format=(value)
    @@default_primary_key_format = value
  end
end
