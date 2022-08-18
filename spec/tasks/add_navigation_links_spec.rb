require "rails_helper"

RSpec.describe "Navigation Links tasks", type: :task do
  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#create" do
    it "creates navigation links for new forem if nonexistent" do
      expect { Rake::Task["navigation_links:create"].invoke }.to change(NavigationLink, :count).by(6)
    end

    context "when navigation links exist" do
      before do
        NavigationLink.destroy_all
        create(:navigation_link,
               name: "Reading List",
               url: URL.url("readinglist"),
               display_to: :logged_in,
               position: 0)
      end

      it "does not create nav links if they already exist" do
        expect { Rake::Task["navigation_links:create"].invoke }.to change(NavigationLink, :count).from(1).to(6)
      end
    end
  end
end
