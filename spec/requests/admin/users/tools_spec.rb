require "rails_helper"
require "view_component/test_helpers"

RSpec.describe "/admin/users/:user_id/tools", type: :request do
  include_examples "Admin::Users::Tools::ShowAction", :admin_user_tools_path, Admin::Users::ToolsComponent
end
