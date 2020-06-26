class LiquidTagBase < Liquid::Tag
  def self.script
    ""
  end

  def validate_data(parse_context)
    validate_contexts(parse_context) if context_restricted?
    validate_user_roles(parse_context) if role_restricted?
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, "").
      gsub(/\n/m, " ").
      gsub(/>\n{1,}</m, "><").
      strip.
      html_safe
  end

  private

  def context_restricted?
    self.class.const_defined? "VALID_CONTEXTS"
  end

  def role_restricted?
    self.class.const_defined? "VALID_ROLES"
  end

  def validate_contexts(parse_context)
    source = parse_context.partial_options[:source]
    raise LiquidTags::Errors::InvalidParseContext, "No source found" unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class.name
    valid_contexts = self.class::VALID_CONTEXTS.map(&:pluralize)
    invalid_source_error_msg = "Invalid context. This liquid tag can only be used in #{valid_contexts}."
    raise LiquidTags::Errors::InvalidParseContext, invalid_source_error_msg unless is_valid_source
  end

  def validate_user_roles(parse_context)
    user = parse_context.partial_options[:user]
    raise LiquidTags::Errors::InvalidParseContext, "No user found" unless user
    raise LiquidTags::Errors::InvalidParseContext, "User is not permitted to use this liquid tag" unless user_permitted_to_use_liquid_tag?(user)
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
