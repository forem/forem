require "rails_helper"

RSpec.describe "Admin deletes user" do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }

  before do
    sign_in admin
    visit admin_user_path(user.id)
  end

  it "enqueues a job for deleting the user" do
    sidekiq_assert_enqueued_jobs(1, only: Users::DeleteWorker) do
      click_button "Delete now"
    end

    message = "@#{user.username} (email: #{user.email}, user_id: #{user.id}) has been fully deleted."
    expect(page).to have_content(message)
  end

  # See: https://github.com/thepracticaldev/tech-private/issues/404
  it "deletes users when they have no email address" do
    user.update(email: nil)

    sidekiq_perform_enqueued_jobs do
      click_button "Delete now"
    end

    message = "@#{user.username} (email: no email, user_id: #{user.id}) has been fully deleted."
    expect(page).to have_content(message)
    expect(User.find_by(id: user.id)).to be_nil
  end
end
