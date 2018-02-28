require 'rails_helper'

RSpec.describe PodcastEpisode, type: :model do
  let(:podcast)        { create(:podcast) }

  it 'accept valid podcast' do
    expect(podcast).to be_valid
  end
end
