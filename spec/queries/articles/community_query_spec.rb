require "rails_helper"

RSpec.describe Articles::CommunityQuery, type: :query do
  it "keeps the public score threshold and current subforem boundary" do
    visible = create(:article, title: "TimescaleDB public")
    hidden = create(:article, title: "TimescaleDB hidden")
    hidden.update_columns(score: Settings::UserExperience.index_minimum_score - 1)
    elsewhere = create(:article, title: "TimescaleDB elsewhere", subforem: create(:subforem))

    expect(described_class.call({ q: "TimescaleDB" }, subforem_id: nil).ids).to eq([visible.id])
    expect(described_class.call({ q: "TimescaleDB" }, subforem_id: elsewhere.subforem_id).ids)
      .to eq([elsewhere.id])
  end

  it "caps page size and breaks equal publication dates by descending ID" do
    first = create(:article, title: "TimescaleDB one")
    second = create(:article, title: "TimescaleDB two")
    second.update_columns(published_at: first.published_at)

    relation = described_class.call({ q: "TimescaleDB", per_page: 1000 })
    expect(relation.limit_value).to eq(100)
    expect(relation.ids).to eq([second.id, first.id])
  end
end
