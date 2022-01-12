class NotificationDecorator < ApplicationDecorator
  NOTIFIABLE_STUB = Struct.new(:name, :id) do
    # @note Should we deprecate this?  It's odd to overwrite an object's `#class` method.
    def class
      Struct.new(:name).new(name)
    end

    # @return [String]
    #
    # @see ApplicationRecord#polymorphic_type_name
    def polymorphic_type_name
      name
    end
  end.freeze

  # returns a stub notifiable object with name and id
  def mocked_object(type)
    return NOTIFIABLE_STUB.new("", nil) if json_data.blank?

    NOTIFIABLE_STUB.new(json_data[type]["class"]["name"], json_data[type]["id"])
  end

  # returns the type of a milestone notification action,
  # eg. "Milestone::Reaction::64"
  def milestone_type
    return "" if action.blank?

    action.split("::").second
  end

  # returns the count of a milestone notification action,
  # eg. "Milestone::Reaction::64"
  def milestone_count
    return "" if action.blank?

    action.split("::").third
  end
end
