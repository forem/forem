# This service removes a profile field and ensures that the corresponding store
# accessor also gets removed immediately.
module ProfileFields
  class Remove
    def self.call(id)
      new(id).call
    end

    attr_reader :profile_field, :error_message

    def initialize(id)
      @id = id
      @success = false
    end

    def call
      @profile_field = ProfileField.find(@id)
      if @profile_field.destroy
        accessor = profile_field.attribute_name.to_s
        Profile.undef_method(accessor) if accessor.in?(Profile.stored_attributes[:data])
        @success = true
      else
        @error_message = @profile_field.errors_as_sentence
      end
      self
    end

    def success?
      @success
    end
  end
end
