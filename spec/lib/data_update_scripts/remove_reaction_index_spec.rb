require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200923173148_remove_reaction_index.rb")

describe DataUpdateScripts::RemoveReactionIndex do
  it "removes reaction index" do
    index_alias = "reactions_#{Rails.env}_alias"
    Search::Client.indices.create(index: index_alias)
    expect(Search::Client.indices.get(index: "*").keys).to include(index_alias)

    described_class.new.run
    expect(Search::Client.indices.get(index: "*").keys).not_to include(index_alias)
  end
end
