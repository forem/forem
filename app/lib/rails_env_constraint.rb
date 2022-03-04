# Used as routing constraint to expose routes only in certain environments.
class RailsEnvConstraint
  # @param [Array<string>] allowed_envs the environments the route(s) will be
  #   available in.
  def initialize(allowed_envs:)
    @allowed_envs = allowed_envs
  end

  # Returns true if we're in an allowed env
  #
  # @note We always ignore the request argument since it's not used.
  # @return [Boolean]
  def matches?(_req = nil)
    # NOTE: ActiveSupport::StringInquirer works with all string methods, so
    # e.g. "test" == "test".inquiry works as expected.
    @allowed_envs.any?(Rails.env)
  end
end
