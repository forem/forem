require "rails_helper"

RSpec.describe Ai::SearchReranker do
  subject(:reranker) do
    described_class.new(query: "rust async programming", scored_articles: scored_articles)
  end

  let(:article_one) do
    create(:article, title: "Roasting coffee beans at home", tags: "watercooler", published: true)
  end
  let(:article_two) do
    create(:article, title: "Building async systems with Rust and Tokio", tags: "rust, backend", published: true)
  end
  let(:article_three) do
    create(:article, title: "Rust ownership and borrowing guide", tags: "rust, tutorial", published: true)
  end

  let(:scored_articles) do
    [
      [article_one, 0.030],
      [article_two, 0.025],
      [article_three, 0.020],
    ]
  end

  context "when :semantic_search_reranking is set to Jev" do
    before { enable_jev_for(:semantic_search_reranking) }

    it "re-ranks candidates by combining Jev noul probability (0.80) and normalized pre-rank score (0.20)" do
      stub_jev(
        "candidate::#{article_one.id}" => 0.05,
        "candidate::#{article_two.id}" => 0.95,
        "candidate::#{article_three.id}" => 0.80,
      )

      result = reranker.rerank

      expect(result.map(&:id)).to eq([article_two.id, article_three.id, article_one.id])
    end

    it "uses a fast 1.2s timeout with zero retries so search latency stays bounded" do
      stub_jev

      reranker.rerank

      expect(Ai::TypeSafe::Client).to have_received(:new)
        .with(hash_including(timeout: 1.2, max_retries: 0))
    end

    it "evaluates at most 50 shortlist candidates in one Jev call and appends the remainder in pre-ranked order" do
      many_articles = Array.new(55) do |idx|
        instance_double(
          Article,
          id: 1000 + idx,
          title: "Article #{idx}",
          cached_tag_list: "ruby",
          description: "Description #{idx}",
          updated_at: Time.zone.at(1_700_000_000),
        )
      end
      many_scored = many_articles.each_with_index.map { |art, idx| [art, 100.0 - idx] }

      requests = stub_jev("candidate::1049" => 0.99)
      result = described_class.new(query: "ruby performance", scored_articles: many_scored).rerank

      expect(requests.length).to eq(1)
      expect(requests.first[:questions].keys.length).to eq(50)
      expect(result.first.id).to eq(1049)
      expect(result.last(5).map(&:id)).to eq([1050, 1051, 1052, 1053, 1054])
    end

    it "sends truncated query and candidate metadata in the Jev payload" do
      requests = stub_jev
      long_query = "q" * 800

      described_class.new(query: long_query, scored_articles: scored_articles).rerank

      expect(requests.first[:state]).to eq(query: "q" * described_class::MAX_QUERY_LENGTH)
      expect(requests.first[:questions].keys).to contain_exactly(
        "candidate::#{article_one.id}",
        "candidate::#{article_two.id}",
        "candidate::#{article_three.id}",
      )
    end

    it "caches Jev probabilities for identical query and candidate shortlist" do
      memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rails).to receive(:cache).and_return(memory_store)

      requests = stub_jev("candidate::#{article_two.id}" => 0.95)

      first_run = described_class.new(query: "rust async", scored_articles: scored_articles).rerank
      second_run = described_class.new(query: "rust async", scored_articles: scored_articles).rerank

      expect(requests.length).to eq(1)
      expect(first_run.map(&:id)).to eq(second_run.map(&:id))
    end

    it "fails open and preserves pre-ranked order when TypeSafe raises an error or times out" do
      client = instance_double(Ai::TypeSafe::Client)
      allow(Ai::TypeSafe::Client).to receive(:new).and_return(client)
      allow(client).to receive(:evaluate).and_raise(Ai::TypeSafe::Client::Error.new("timeout", status_code: nil))

      expect(reranker.rerank).to eq([article_one, article_two, article_three])
    end

    it "returns pre-ranked order without calling Jev when there is only 1 candidate" do
      requests = stub_jev

      result = described_class.new(query: "rust", scored_articles: [[article_one, 1.0]]).rerank

      expect(result).to eq([article_one])
      expect(requests).to be_empty
    end
  end

  it "does not call Jev when :semantic_search_reranking is off, even with a TypeSafe key" do
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "test-typesafe-key")
    allow(Ai::TypeSafe::Client).to receive(:new)

    expect(reranker.rerank).to eq([article_one, article_two, article_three])
    expect(Ai::TypeSafe::Client).not_to have_received(:new)
  end

  it "does not call Jev when Jev is selected but the TypeSafe key is missing" do
    enable_jev_for(:semantic_search_reranking)
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", nil)
    allow(Ai::TypeSafe::Client).to receive(:new)

    expect(reranker.rerank).to eq([article_one, article_two, article_three])
    expect(Ai::TypeSafe::Client).not_to have_received(:new)
  end
end
