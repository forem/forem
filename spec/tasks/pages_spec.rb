require "rails_helper"

RSpec.describe "Pages tasks", type: :task do
  let!(:filepath) { Rails.root.join("tmp/page.html") }
  let!(:original_content) { "<h1>Hello Page</h1>" }
  let!(:new_content) { "<h2>Hello updated Page</h2>" }

  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
    File.write(filepath, original_content)
  end

  # Ensure the fixture never changes after each run
  after { File.delete(filepath) if File.file?(filepath) }

  describe "#sync" do
    it "updates a Page HTML content when a given file to sync has changed" do
      page = create(:page, body_html: original_content)

      threads = []
      threads << Thread.new do
        # Thread that runs the long lived rake task
        Rake::Task["pages:sync"].invoke(page.slug, filepath)
      end

      threads << Thread.new do
        # This thread gives the rake task time to boot before updating the file
        sleep 0.5
        File.write(filepath, new_content)

        # Wait again so the rake task can do its work before killing it
        sleep 0.5
        Thread.kill(threads.first)
        sleep 0.1 while threads.first.alive?
      end

      threads.each(&:join)
      page = Page.find(page.id)
      expect(page.body_html).to include(new_content)
    end
  end
end
