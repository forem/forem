require 'yard'
require 'active_support/inflector'

module YARD::Handlers::Ruby::ActiveRecord::Fields
  class CreateTableHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:create_table)

    def process
      return unless globals.ar_schema
      globals.klass = ActiveSupport::Inflector.singularize call_params.first.camelize
      if P(globals.klass).class == YARD::CodeObjects::Proxy
        # Try module with the first part
        globals.klass = globals.klass.underscore.split('_',2).map(&:camelize).join('::')
      end
      parse_block(statement.last.last)
      globals.klass = nil
    end
  end
end