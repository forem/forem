require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let(:user) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    Delayed::Worker.delay_jobs = true
    Delayed::Worker.destroy_failed_jobs = false
  end

  after do
    Delayed::Worker.delay_jobs = false
  end

  it "banishes user asynchronously" do
    create(:article, user: user)
    post "/internal/users/#{user.id}/banish"
    Delayed::Worker.new(quiet: false).work_off
    expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
  end
end
