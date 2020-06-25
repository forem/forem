class LiquidTagBase < Liquid::Tag
  def self.script
    ""
  end

  def validate_data(parsed_context)
    source = parsed_context.partial_options[:source]
    validate_contexts(source)

    user = parsed_context.partial_options[:user]
    validate_user_permissions(user)
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, "").
      gsub(/\n/m, " ").
      gsub(/>\n{1,}</m, "><").
      strip.
      html_safe
  end

  class LiquidTagError < StandardError; end

  private

  def validate_contexts(source)
    raise LiquidTagError, "No source found" unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class_name
    invalid_source_error_msg = "Invalid context. This liquid tag can only be used in #{self.class::VALID_CONTEXTS.join(', ')}."

    raise LiquidTagError, invalid_source_error_msg unless is_valid_source
  end

  def validate_user_permissions(user)
    raise LiquidTagError, "No user found" unless user

    raise LiquidTagError, "User is not permitted to use this liquid tag" unless user_permitted_to_use_liquid_tag?(user)
  end

  def user_permitted_to_use_liquid_tag?(user)
    self.class::VALID_ROLES.any? { |valid_role| user_has_valid_role?(user, valid_role) }
  end

  def user_has_valid_role?(user, valid_role)
    # Single resource roles require 2 arguments - the role and the resource
    if valid_role.is_a? Array
      role, resource = valid_role

      user.has_role? role, resource
    else
      user.has_role? valid_role
    end
  end
end
