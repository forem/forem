# @abstract
#
# We created this class as a wrapper to `Liquid::Tag`.  This follows
# Forem's aspirational architectural decision to create
# wrapping/insulating classes around our gem dependencies.
#
# This pattern is analogous to creating ApplicationRecord models that
# inherit from ActiveRecord::Base.
#
# @note When making a new Liquid tag, inherit from this class instead
#       of `Liquid::Base`.
#
# @see https://github.com/Shopify/liquid
class LiquidTagBase < Liquid::Tag
  # The method name to send the user to ask whether or not they
  # have access to the given liquid tag.
  #
  # @see LiquidTagPolicy
  #
  # @note My preference would be to use `class_attribute` as it keeps
  #       things tidier, but that's not a hard preference.
  #
  # @note Should we verify that the user responds to this given method?
  def self.user_authorization_method_name
    nil
  end

  def self.script
    ""
  end

  # @param _tag_name [String] When you do `{% embed <url> %}` the "embed" is the tag name.
  # @param _content [String] The stuff between the tag name and the end of the liquid declaration.
  # @param parse_context [Hash]
  # @option parse_context [User] :user the user who's using the liquid tag (likely the article's
  #         author).
  # @option parse_context [Object] :source we're rendering this liquid tag "in" something, the
  #         source is that something.  Examples iniclude Article.
  # @option parse_context [ApplicationPolicy] :policy There are cases where we want to update liquid
  #         tags en-masse (see https://github.com/forem/forem/pull/16460).  However, it's possible
  #         the current user doesn't have permission to use this liquid tag.  This is the "backdoor"
  #         for allowing that feature.  In most cases, however, we should use the LiquidTagPolicy.
  def initialize(_tag_name, _content, parse_context)
    super
    validate_contexts
    # This check issues DB queries so we keep it as the last one
    Pundit.authorize(
      parse_context.partial_options[:user],
      self,
      :initialize?,
      policy_class: parse_context.partial_options.fetch(:policy) { LiquidTagPolicy },
    )
  end

  def strip_tags(string)
    ActionController::Base.helpers.strip_tags(string).strip
  end

  def pattern_match_for(input, regex_options)
    regex_options
      .filter_map { |regex| input.match(regex) }
      .first
  end

  # this method checks for presence of named capture group in match
  def match_has_named_capture_group?(match, group_name)
    match.names.include?(group_name)
  end

  # A method to help collaborators not need to reach into the class
  # implementation details.
  def user_authorization_method_name
    self.class.user_authorization_method_name
  end

  private

  def validate_contexts
    return unless self.class.const_defined? :VALID_CONTEXTS

    source = parse_context.partial_options[:source]
    raise LiquidTags::Errors::InvalidParseContext, I18n.t("liquid_tags.liquid_tag_base.no_source_found") unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class.name
    return if is_valid_source

    valid_contexts = self.class::VALID_CONTEXTS.map(&:pluralize).join(", ")
    invalid_source_error_msg = I18n.t("liquid_tags.liquid_tag_base.invalid_context", valid: valid_contexts)
    raise LiquidTags::Errors::InvalidParseContext, invalid_source_error_msg
  end
end
