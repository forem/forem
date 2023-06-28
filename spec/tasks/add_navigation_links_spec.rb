require "rails_helper"

RSpec.describe "Navigation Links tasks", type: :task do
  before do
    Rake.application["navigation_links:create"].reenable

    %w[home readinglist contact code_of_conduct privacy terms].each do |page|
      Rake.application["navigation_links:find_or_create:#{page}"].reenable
    end
  end

  it "creates navigation links for new forem if nonexistent" do
    expect { Rake::Task["navigation_links:create"].invoke }.to change(NavigationLink, :count).by(6)
  end

  it "does not create nav links if they already exist" do
    create(:navigation_link, name: "Reading List", url: URL.url("readinglist"), display_to: :logged_in, position: 0)

    expect { Rake::Task["navigation_links:create"].invoke }.to change(NavigationLink, :count).from(1).to(6)
  end
end
