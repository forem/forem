module YARD::Handlers::Ruby::ActiveRecord::Fields
  class DefineHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:define)
    
    def process
      if statement.file == 'db/schema.rb'
        globals.ar_schema = true
        parse_block(statement.last.last)
        globals.ar_schema = false
      end
    end
  end
end
