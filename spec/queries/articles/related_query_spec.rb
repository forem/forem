require "rails_helper"

RSpec.describe Articles::RelatedQuery, type: :query do
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

  it "keeps filtered_scope predicates sargable so date and score indexes remain usable" do
    sql = described_class.new({ q: "TimescaleDB", start: "2026-11-01", end: "2026-11-10" }).filtered_scope.to_sql
    expect(sql).not_to include("INTERVAL '0 seconds'")
    expect(sql).not_to include("articles.score + 0")
  end

  it "rejects non-numeric pagination strings" do
    expect { described_class.call({ q: "TimescaleDB", page: "abc" }) }
      .to raise_error(Articles::RelatedQuery::InvalidRequest, /page/)
    expect { described_class.call({ q: "TimescaleDB", per_page: "xyz" }) }
      .to raise_error(Articles::RelatedQuery::InvalidRequest, /per_page/)
  end
end
