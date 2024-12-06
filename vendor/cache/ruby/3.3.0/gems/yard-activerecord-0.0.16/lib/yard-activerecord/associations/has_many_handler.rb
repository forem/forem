require_relative 'plural_handler'

module YARD::Handlers::Ruby::ActiveRecord::Associations
  class HasManyHandler < PluralHandler
    handles method_call(:has_many)

    def group_name
      'Has many'
    end

    private
    def return_description
      ''
    end
  end
end