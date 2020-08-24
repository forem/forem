class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  # A dynamic mixin so the wrapper methods on user update automatically.
  # See: https://dev.to/appsignal/configurable-ruby-modules-the-module-builder-pattern-4483
  USER_MIXIN = Module.new

  # NOTE: @citizen428 This is a temporary mapping so we don't break DEV during
  # profile migration/generalization work.
  MAPPED_ATTRIBUTES = {
    brand_color1: :bg_color_hex,
    brand_color2: :text_color_hex,
    display_email_on_profile: :email_public,
    display_looking_for_work_on_profile: :looking_for_work_publicly,
    git_lab_url: :gitlab_url,
    linked_in_url: :linkedin_url,
    recruiters_can_contact_me_about_job_opportunities: :contact_consent,
    stack_overflow_url: :stackoverflow_url
  }.with_indifferent_access.freeze

  # Generates typed accessors for all currently defined profile fields.
  def self.refresh_attributes!
    ProfileField.find_each do |field|
      attribute_name = field.attribute_name
      store_attribute :data, attribute_name, field.type

      getter = MAPPED_ATTRIBUTES.fetch(attribute_name, attribute_name).to_s
      USER_MIXIN.instance_eval do
        define_method(getter) do
          if profile.respond_to?(attribute_name)
            profile.public_send(attribute_name)
          else
            self[getter]
          end
        end

        # Make mapped attributes available under both names
        alias_method(attribute_name, getter) if attribute_name != getter
      end
    end
  end

  refresh_attributes!

  # Returns an array of all currently defined `store_attribute`s on `data`.
  def self.attributes
    stored_attributes[:data]
  end

  # NOTE: @citizen428 This is a temporary mapping so we don't break DEV during
  # profile migration/generalization work.
  def self.mapped_attributes
    attributes.map { |attribute| MAPPED_ATTRIBUTES.fetch(attribute, attribute).to_s }
  end
end
