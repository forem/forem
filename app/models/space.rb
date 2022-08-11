# This class helps deliver on the "Authorization System: use case 1-1".  In upcoming use cases we
# will begin to look toward multiple spaces.  For the moment, let's use this narrow definition to
# move us forward.
#
# @see https://github.com/orgs/forem/projects/46
#
# @note This class exists to assist with authorization and exposing an "ActiveModel" compliant
#       interface for form work.
class Space
  # ...the final frontier.
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :limit_post_creation_to_admins, :boolean, default: lambda {
                                                                 FeatureFlag.enabled?(:limit_post_creation_to_admins)
                                                               }

  # A convenience method to maintain Ruby idioms
  alias limit_post_creation_to_admins? limit_post_creation_to_admins

  DEFAULT = "default".freeze

  # @note Right now there's only one space..."default"; this is used to generate the URL for our update.
  def to_param
    DEFAULT
  end

  def save
    if limit_post_creation_to_admins?
      FeatureFlag.enable(:limit_post_creation_to_admins)
    else
      FeatureFlag.disable(:limit_post_creation_to_admins)
    end

    Spaces::BustCachesForSpaceChangeWorker.perform_async

    # I want to ensure that we're returning true, to communicate that the "save" was successful.
    true
  end
end
