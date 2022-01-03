require "rails_helper"

RSpec.describe "/admin/users/:user_id/tools/emails", type: :request do
  include_examples "Admin::Users::Tools::ShowAction", :admin_user_tools_emails_path,
                   Admin::Users::Tools::EmailsComponent
end
