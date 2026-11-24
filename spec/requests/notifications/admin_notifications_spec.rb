require "rails_helper"

RSpec.describe "Admin notifications on /notifications" do
  let(:user) { create(:user) }

  it "renders the title, the escaped body and the link" do
    actor = create(:user)
    create(:notification, user: user, organization: nil, notifiable: create(:admin_notification), action: nil,
                          json_data: Notifications::AdminNotifications.json_data(
                            { "title" => "Your MLH application", "body" => "<b>Line one</b>\nLine two",
                              "url" => "https://mlh.io/apply" },
                            actor: actor,
                          ))
    sign_in user

    get "/notifications"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your MLH application", "&lt;b&gt;Line one&lt;/b&gt;", 'href="https://mlh.io/apply"',
                                     I18n.t("views.notifications.admin_notification.open"))
    expect(response.body).not_to include("<b>Line one</b>")
  end
end
