require "rails_helper"

RSpec.describe PodcastTag, type: :liquid_tag do
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:valid_long_slug) { "/#{podcast.slug}/#{podcast_episode.slug}" }

  before { Liquid::Template.register_tag("podcast", described_class) }

  def generate_podcast_liquid_tag(link)
    Liquid::Template.parse("{% podcast #{link} %}")
  end

  context "when given valid link" do
    it "fetches target podcast" do
      liquid = generate_podcast_liquid_tag(valid_long_slug)
      expect(liquid.root.nodelist.first.episode).to eq(podcast_episode)
    end

    it "raises error if podcast does not exist" do
      expect do
        generate_podcast_liquid_tag("#{valid_long_slug}1")
      end.to raise_error(StandardError)
    end
  end

  it "render properly" do
    rendered = generate_podcast_liquid_tag(valid_long_slug).render
    expect(rendered).not_to eq "Liquid error: internal"
  end

  it "rejects invalid link" do
    expect do
      generate_podcast_liquid_tag("https://dev.to/toolsday/hardware/test/2")
    end.to raise_error(StandardError)
  end
end
