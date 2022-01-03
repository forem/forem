require "rails_helper"

RSpec.describe "/admin/users/:user_id/tools/organizations", type: :request do
  include_examples "Admin::Users::Tools::ShowAction", :admin_user_tools_reports_path,
                   Admin::Users::Tools::ReportsComponent
end
