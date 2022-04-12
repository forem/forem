require "rails_helper"

RSpec.describe "/admin/users/export", type: :request do
  let(:admin) do
    create(:user, :super_admin,
           name: "Admin1", username: "admin1", email: "admin1@gmail.com",
           registered_at: "2020-05-06T13:09:47+0000")
  end
  let!(:user) do
    create(:user, :org_member,
           name: "John Doe", username: "john_doe", email: "john_doe@gmail.com",
           registered_at: "2020-06-08T13:09:47+0000")
  end

  before do
    sign_in(admin)
    get "#{export_admin_users_path}.csv"
  end

  it "renders successfully" do
    expect(response).to have_http_status :ok
  end

  it "renders the headers" do
    expect(response.body).to include("Name,Username,Email address,Status,Joining date,Last activity,Organizations")
  end

  it "shows the correct number of total rows" do
    # This takes into account empty lines after each row
    expect(response.body.lines.count).to eq(3)
  end

  it "shows the correct fields", :aggregate_failures do
    expect(response.body).to include('Admin1,admin1,admin1@gmail.com,Good Standing,"06 May, 2020","06 May, 2020",[]')
    # rubocop:disable Style/PercentLiteralDelimiters, Layout/LineLength
    expect(response.body).to include(
      %{John Doe,john_doe,john_doe@gmail.com,Good Standing,"08 Jun, 2020","08 Jun, 2020","[""#{user.organizations.first.name}""]"},
    )
    # rubocop:enable Style/PercentLiteralDelimiters, Layout/LineLength
  end
end
