require "rails_helper"

RSpec.describe Search::Reaction, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: "Reaction" do
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:reaction1) { create(:reaction, category: "readinglist", reactable: article1) }
    let(:reaction2) { create(:reaction, category: "readinglist", reactable: article2) }
    let(:query_params) { { size: 5 } }

    it "parses reaction document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    it "returns fields necessary for the view" do
      view_keys = %w[id reactable]
      reactable_keys = %w[title path published_date_string tags user]
      user_keys = %w[username name profile_image_90]
      index_documents([reaction1])

      result = described_class.search_documents(params: { size: 1 })
      reaction_doc = result["reactions"].first
      expect(result["total"]).to be_present
      expect(reaction_doc.keys).to include(*view_keys)
      expect(reaction_doc["reactable"].keys).to include(*reactable_keys)
      expect(reaction_doc.dig("reactable", "user").keys).to include(*user_keys)
    end

    context "with a query" do
      it "searches by search_fields" do
        allow(article1).to receive(:title).and_return("ruby")
        allow(article2).to receive(:body_text).and_return("Ruby Tuesday")
        index_documents([reaction1, reaction2])
        query_params[:search_fields] = "ruby"

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(2)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction1.id, reaction2.id)
      end
    end

    context "with a filter term" do
      let(:tag_one) { create(:tag) }
      let(:tag_two) { create(:tag) }

      it "filters by tag names" do
        article1.tags << tag_one
        article2.tags << tag_two
        index_documents([reaction1, reaction2])
        query_params[:tag_names] = [tag_one.name]

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction1.id)
      end

      it "filters by multiple tag names when tag_boolean_mode is set to all" do
        article1.tags << tag_one
        article2.tags << tag_two
        article2.tags << tag_one
        index_documents([reaction1, reaction2])
        query_params[:tag_names] = [tag_one.name, tag_two.name]
        query_params[:tag_boolean_mode] = "all"

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
      end

      it "filters by user_id" do
        index_documents([reaction1, reaction2])
        query_params[:user_id] = reaction1.user_id

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction1.id)
      end

      it "filters by status" do
        reaction1.update(status: "invalid")
        index_documents([reaction1, reaction2])
        query_params[:status] = %w[valid confirmed]

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
      end

      it "filters by category by default" do
        reaction1.update(category: "like")
        index_documents([reaction1, reaction2])

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
      end
    end

    context "with default sorting" do
      xit "sorts by id" do
        index_documents([reaction1, reaction2])

        reaction_docs = described_class.search_documents(params: query_params)["reactions"]
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to eq([reaction2.id, reaction1.id])
      end
    end
  end
end
