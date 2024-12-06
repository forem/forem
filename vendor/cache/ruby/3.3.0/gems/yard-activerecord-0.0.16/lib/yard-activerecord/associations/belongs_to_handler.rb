require_relative 'singular_handler'

module YARD::Handlers::Ruby::ActiveRecord::Associations
  class BelongsToHandler < SingularHandler
    handles method_call(:belongs_to)

    def group_name
      'Belongs to'
    end

    private
    def return_description
      ''
    end
  end
end
