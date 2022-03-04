# ConsumerApp::FOREM_APP_PLATFORMS are all the platforms supported by every
# Forem instance by default. These are App Integrations that populate their
# credentials from ENV variables and are not meant to be modified by creators.
# Creator apps are those dynamically managed by creators in the Admin dashboard.
class ConsumerAppPolicy < ApplicationPolicy
  def create?
    @record.creator_app?
  end

  alias edit? create?

  alias update? create?

  alias destroy? create?
end
