require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200924140813_remove_reaction_index_by_name.rb")

describe DataUpdateScripts::RemoveReactionIndexByName do
  it "removes reaction index" do
    index_name = "reactions_#{Rails.env}"
    Search::Client.indices.create(index: index_name)
    expect(Search::Client.indices.get(index: "*").keys).to include(index_name)

    described_class.new.run
    expect(Search::Client.indices.get(index: "*").keys).not_to include(index_name)
  end
end
