# frozen_string_literal: true

require 'with_model/model'
require 'with_model/model/dsl'
require 'with_model/table'
require 'with_model/version'

module WithModel
  class MiniTestLifeCycle < Module
    def initialize(object)
      define_method :before_setup do
        object.create
        super() if defined?(super)
      end

      define_method :after_teardown do
        object.destroy
        super() if defined?(super)
      end
    end

    def self.call(object)
      new(object)
    end
  end

  class << self
    attr_writer :runner
  end

  def self.runner
    @runner ||= :rspec
  end

  # @param [Symbol] name The constant name to assign the model class to.
  # @param scope Passed to `before`/`after` in the test context. RSpec only.
  # @param options Passed to {WithModel::Model#initialize}.
  # @param block Yielded an instance of {WithModel::Model::DSL}.
  def with_model(name, scope: nil, **options, &block)
    runner = options.delete(:runner)
    model = Model.new name, **options
    dsl = Model::DSL.new model
    dsl.instance_exec(&block) if block

    setup_object(model, scope: scope, runner: runner)
  end

  # @param [Symbol] name The table name to create.
  # @param scope Passed to `before`/`after` in the test context. Rspec only.
  # @param options Passed to {WithModel::Table#initialize}.
  # @param block Passed to {WithModel::Table#initialize} (like {WithModel::Model::DSL#table}).
  def with_table(name, scope: nil, **options, &block)
    runner = options.delete(:runner)
    table = Table.new name, options, &block

    setup_object(table, scope: scope, runner: runner)
  end

  private

  # @param [Object] object The new model object instance to create
  # @param scope Passed to `before`/`after` in the test context. Rspec only.
  # @param [Symbol] runner The test running, either :rspec or :minitest, defaults to :rspec
  def setup_object(object, scope: nil, runner: nil) # rubocop:disable Metrics/MethodLength
    case runner || WithModel.runner
    when :rspec
      before(*scope) do
        object.create
      end

      after(*scope) do
        object.destroy
      end
    when :minitest
      class_eval do
        include MiniTestLifeCycle.call(object)
      end
    else
      raise ArgumentError, 'Unsupported test runner set, expected :rspec or :minitest'
    end
  end
end
