# frozen_string_literal: true

::ActiveRecord::Associations::Builder::HasOne.class_eval do
  # Based on
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/builder/collection_association.rb#L50
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/builder/singular_association.rb#L11
  def self.define_accessors(mixin, reflection)
    super
    name = reflection.name
    mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{name}_id
        # if an attribute is already defined with this methods name we should just use it
        return read_attribute(__method__) if has_attribute?(__method__)
        association(:#{name}).reader.try(:id)
      end
    CODE
  end
end
