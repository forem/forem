require 'helper'
require 'active_record'
require 'rails/generators/test_case'
require 'generators/flipper/active_record_generator'

class FlipperActiveRecordGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::ActiveRecordGenerator
  destination File.expand_path('../../../../tmp', __FILE__)
  setup :prepare_destination

  def test_generates_migration
    run_generator
    migration_version = if Rails::VERSION::MAJOR.to_i < 5
                          ""
                        else
                          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
                        end
    assert_migration 'db/migrate/create_flipper_tables.rb', <<~MIGRATION
      class CreateFlipperTables < ActiveRecord::Migration#{migration_version}
        def self.up
          create_table :flipper_features do |t|
            t.string :key, null: false
            t.timestamps null: false
          end
          add_index :flipper_features, :key, unique: true

          create_table :flipper_gates do |t|
            t.string :feature_key, null: false
            t.string :key, null: false
            t.string :value
            t.timestamps null: false
          end
          add_index :flipper_gates, [:feature_key, :key, :value], unique: true
        end

        def self.down
          drop_table :flipper_gates
          drop_table :flipper_features
        end
      end
    MIGRATION
  end
end
