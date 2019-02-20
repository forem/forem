require "rails_helper"

RSpec.describe PodcastEpisodeDecorator, type: :decorator do
  describe "#comments_to_show_count" do
    it "return 25 if it's not discuess" do
      pe = build_stubbed(:podcast_episode).decorate
      expect(pe.comments_to_show_count).to eq(25)
    end
  end
end
