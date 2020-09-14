# This service creates a new profile field and ensures that the correct store
# accessor gets added to profiles immediately.
module ProfileFields
  class Add
    def self.call(attributes)
      new(attributes).call
    end

    attr_reader :profile_field, :error_message

    def initialize(attributes)
      @attributes = attributes
      @success = false
    end

    def call
      @profile_field = ProfileField.create(@attributes)
      if @profile_field.persisted?
        @success = true
        Profile.refresh_attributes!
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
