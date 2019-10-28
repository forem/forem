class Internal::PermissionsController < Internal::ApplicationController
  layout "internal"

  def index
    @users = User.with_role(:admin).to_a + User.with_role(:super_admin).to_a + User.with_role(:single_resource_admin, :any)
  end
end
