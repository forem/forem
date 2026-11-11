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

  it "matches a multi-word term only where the words are adjacent", :aggregate_failures do
    adjacent = create(:article, title: "Tiger Data ships faster hypertables")
    apart = create(:article, title: "A tiger at the zoo produced a lot of data")

    ids = described_class.call({ q: "Tiger Data" }).ids

    expect(ids).to include(adjacent.id)
    expect(ids).not_to include(apart.id)
  end

  it "matches a phrase that contains a short connecting word" do
    article = create(:article, title: "Notes on state of the art retrieval")

    expect(described_class.call({ q: "state of the art" }).ids).to eq([article.id])
  end

  it "matches a multi-word phrase containing a hyphenated compound word", :aggregate_failures do
    exact = create(:article, title: "Tracing microservices with Orion X-Ray in production")
    separated = create(:article, title: "Orion guide with an unrelated X-Ray note at the end")
    unhyphenated_parts = create(:article, title: "Orion system with x axis and ray casting")

    ids = described_class.call({ q: "Orion X-Ray" }).ids

    expect(ids).to eq([exact.id])
    expect(ids).not_to include(separated.id, unhyphenated_parts.id)
  end

  it "caps multi-word phrases at MAX_SEARCH_TSQUERY_TERMS tokens while preserving punctuation" do
    article = create(:article, title: "One two three four five six seven eight X-Ray guide")

    ids = described_class.call({ q: "one two three four five six seven eight X-Ray extra" }).ids

    expect(ids).to eq([article.id])
  end

  it "keeps prefix matching for single-word terms" do
    article = create(:article, title: "TimescaleDB internals explained")

    expect(described_class.call({ q: "Timescale" }).ids).to eq([article.id])
  end

  it "still rejects a term with no searchable characters" do
    expect { described_class.call({ q: "!!!" }) }
      .to raise_error(described_class::InvalidRequest)
  end
end
