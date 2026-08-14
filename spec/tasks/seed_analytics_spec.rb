require "rails_helper"

RSpec.describe "db:seed:analytics", type: :task do
  before do
    Rake::Task["db:seed:analytics"].reenable
  end

  it "raises in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    expect { Rake::Task["db:seed:analytics"].invoke }.to raise_error(RuntimeError, /production/)
  end

  it "seeds analytics data" do
    create_list(:user, 4)
    article = create(:article, published: true, user: User.first)

    expect {
      Rake::Task["db:seed:analytics"].invoke
    }.to change(PageView, :count).and change(Reaction, :count).and change(Comment, :count)
  end
end