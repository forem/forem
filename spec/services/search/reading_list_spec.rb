require "rails_helper"

RSpec.describe Search::ReadingList, type: :service do
  describe "::search_documents", elasticsearch: "FeedContent" do
    let(:user) { create(:user) }
    let(:article0) { create(:article) }
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:reaction1) { create(:reaction, user: user, category: "readinglist", reactable: article1) }
    let(:reaction2) { create(:reaction, user: user, category: "readinglist", reactable: article2) }
    let(:reaction3) { create(:reaction, user: user, category: "readinglist", reactable: article0) }
    let(:query_params) { {} }

    before do
      reaction1
      reaction2
    end

    def index_documents(docs)
      index_documents_for_search_class(Array.wrap(docs), Search::FeedContent)
    end

    it "returns fields necessary for the view" do
      view_keys = %w[id reactable user_id]
      reactable_keys = %w[title path readable_publish_date_string tags user]
      user_keys = %w[username name profile_image_90]
      index_documents(article1)

      result = described_class.search_documents(params: {}, user: user)
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
        index_documents([article1, article2])
        query_params[:search_fields] = "ruby"

        reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
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
        index_documents([article1, article2])
        query_params[:tag_names] = [tag_one.name]

        reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction1.id)
        expect(doc_ids).not_to include(reaction2.id)
      end

      it "filters by multiple tag names when tag_boolean_mode is set to all" do
        article1.tags << tag_one
        article2.tags << tag_two
        article2.tags << tag_one
        index_documents([article1, article2])
        query_params[:tag_names] = [tag_one.name, tag_two.name]
        query_params[:tag_boolean_mode] = "all"

        reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
        expect(doc_ids).not_to include(reaction1.id)
      end

      it "filters by status" do
        reaction1.update(status: "invalid")
        index_documents([article1, article2])
        query_params[:status] = %w[valid confirmed]

        reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
      end

      it "only returns readinglist reactions" do
        reaction1.update(category: "like")
        index_documents([article1, article2])

        reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
        expect(reaction_docs.count).to eq(1)
        doc_ids = reaction_docs.map { |t| t["id"] }
        expect(doc_ids).to include(reaction2.id)
        expect(doc_ids).not_to include(reaction1.id)
      end
    end

    it "sorts by reaction ID DESC" do
      reaction3
      index_documents([article0, article1, article2])

      reaction_docs = described_class.search_documents(params: query_params, user: user)["reactions"]
      doc_ids = reaction_docs.map { |t| t["id"] }
      expect(doc_ids).to eq([reaction3.id, reaction2.id, reaction1.id])
    end
  end
end
