require "rails_helper"

RSpec.describe Search::Postgres::ReadingList, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:article_not_in_reading_list) { create(:article) }
  let(:article_1) { create(:article, with_tags: false) }
  let(:article_2) { create(:article, with_tags: false) }

  def extract_from_results(result, attribute)
    result[:items].pluck(:reactable).pluck(attribute)
  end

  describe "::search_documents" do
    before do
      create(:reaction, user: user, reactable: article, category: :readinglist, status: :valid)
    end

    it "returns an empty result without a user" do
      expect(described_class.search_documents(nil)).to be_empty
    end

    it "does not include an article not in the reading list" do
      result = described_class.search_documents(user)
      expect(extract_from_results(result, :path)).not_to include(article_not_in_reading_list.path)
    end

    it "does not return an article belonging to another user's reading list" do
      create(
        :reaction,
        reactable: article_not_in_reading_list,
        category: :readinglist,
        user: article_not_in_reading_list.user,
      )

      result = described_class.search_documents(user)
      expect(extract_from_results(result, :path)).not_to include(article_not_in_reading_list.path)
    end

    it "returns results of articles in the reading list" do
      result = described_class.search_documents(user)
      expect(extract_from_results(result, :path)).to include(article.path)
    end

    it "returns the total count of the articles in the reading list" do
      articles = create_list(:article, 2)
      articles.each { |article| create(:reaction, category: :readinglist, reactable: article, user: user) }

      result = described_class.search_documents(user)
      expect(result[:total]).to eq(user.reactions.readinglist.count)
    end

    context "when describing the result format" do
      let(:result) { described_class.search_documents(user) }

      it "returns the correct attributes for the result", :aggregate_failures do
        expect(result.keys).to match_array(%i[items total])
        expect(result[:total]).to be_present
        expect(result[:items]).to be_present
      end

      it "returns the correct attributes for a reading list item", :aggregate_failures do
        item = result[:items].first

        expect(item.keys).to match_array(%i[id user_id reactable])
        expect(item[:id]).to eq(user.reactions.readinglist.first.id)
        expect(item[:user_id]).to eq(user.id)
      end

      it "returns the correct attributes for a reading list item's reactable", :aggregate_failures do
        item = result[:items].first
        reactable = item[:reactable]

        expect(reactable.keys).to match_array(
          %i[
            path readable_publish_date_string reading_time
            tag_list tags title user
          ],
        )
        expect(reactable[:path]).to eq(article.path)
        expect(reactable[:readable_publish_date_string]).to eq(article.readable_publish_date)
        expect(reactable[:reading_time]).to eq(article.reading_time)
        tags = article.cached_tag_list.to_s.split(", ")
        expect(reactable[:tag_list]).to eq(tags)
        expect(reactable[:tags]).to eq(tags.map { |tag| { name: tag } })
        expect(reactable[:title]).to eq(article.title)
      end

      it "returns the correct attributes for a reading list item's reactable's user", :aggregate_failures do
        item = result[:items].first
        reactable = item[:reactable]

        reactable_user = reactable[:user]
        expect(reactable_user.keys).to eq(%i[name profile_image_90 username])
        expect(reactable_user[:name]).to eq(article.user.name)
        expect(reactable_user[:profile_image_90]).to eq(article.user.profile_image_90)
        expect(reactable_user[:username]).to eq(article.user.username)
      end
    end

    context "when filtering by statuses" do
      it "returns confirmed items by default" do
        item = user.reactions.readinglist.last
        item.update_columns(status: :confirmed)

        expect(described_class.search_documents(user)[:items].first[:id]).to eq(item.id)
      end

      it "returns valid items by default" do
        item = user.reactions.readinglist.last
        item.update_columns(status: :valid)

        expect(described_class.search_documents(user)[:items].first[:id]).to eq(item.id)
      end

      it "selects archived items upon request", :aggregate_failures do
        valid_item = user.reactions.readinglist.last
        archived_item = create(:reaction, user: user, category: :readinglist, status: :archived)

        # rubocop:disable Rails/PluckId
        ids = described_class.search_documents(user, statuses: :archived)[:items].pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to include(archived_item.id)
        expect(ids).not_to include(valid_item.id)
      end
    end

    context "when filtering by tags" do
      after do
        user.reactions.readinglist.delete_all
      end

      it "filters out items belonging to an article without the requested tag" do
        article_1.tag_list.add(:beginners)
        article_1.save!

        create(:reaction, reactable: article_1, user: user, category: :readinglist)

        result = described_class.search_documents(user, tags: [:foobar])
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "selects items belonging to an article with the requested tag" do
        article_1.tag_list.add(:beginners)
        article_1.save!

        create(:reaction, reactable: article_1, user: user, category: :readinglist)

        result = described_class.search_documents(user, tags: [:beginners])
        expect(extract_from_results(result, :path)).to match_array([article_1.path])
      end

      it "selects items belonging to an article with all the requested tags", :aggregate_failures do
        article_1.tag_list.add(:beginners)
        article_1.tag_list.add(:ruby)
        article_1.save!

        article_2.tag_list.add(:beginners)
        article_2.save!

        create(:reaction, reactable: article_1, user: user, category: :readinglist)
        create(:reaction, reactable: article_2, user: user, category: :readinglist)

        result = described_class.search_documents(user, tags: %i[beginners ruby])
        expect(extract_from_results(result, :path)).to include(article_1.path)
        expect(extract_from_results(result, :path)).not_to include(article_2.path)
      end
    end

    context "when filtering by statuses and tags" do
      it "selects items with the requested statuses and articles tags", :aggregate_failures do
        article_1.tag_list.add(:beginners)
        article_2.tag_list.add(:beginners)
        article_1.save!
        article_2.save!

        valid_item = create(:reaction, category: :readinglist, user: user, reactable: article_1, status: :valid)
        archived_item = create(:reaction, category: :readinglist, user: user, reactable: article_2, status: :archived)

        result = described_class.search_documents(user, statuses: %i[valid], tags: %i[beginners])

        # rubocop:disable Rails/PluckId
        item_ids = result[:items].pluck(:id)
        # rubocop:enable Rails/PluckId
        expect(item_ids).to include(valid_item.id)
        expect(item_ids).not_to include(archived_item.id)
      end
    end

    context "when searching for a term" do
      it "matches against the article's body_markdown", :aggregate_failures do
        article.update_columns(body_markdown: "Life of the party")

        result = described_class.search_documents(user, term: "part")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "fiesta")
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "matches against the article's title", :aggregate_failures do
        article.update_columns(title: "Life of the party")

        result = described_class.search_documents(user, term: "part")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "fiesta")
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "matches against the article's tags", :aggregate_failures do
        article.update_columns(cached_tag_list: "javascript, beginners, ruby")

        result = described_class.search_documents(user, term: "beginner")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "newbie")
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "matches against the article's organization's name", :aggregate_failures do
        article.organization = create(:organization, name: "ACME corp")
        article.save!

        result = described_class.search_documents(user, term: "ACME")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "ECMA")
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "matches against the article's user's name", :aggregate_failures do
        article_user = article.user
        article_user.update_columns(name: "Friday Sunday")

        result = described_class.search_documents(user, term: "Frida")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "Sat")
        expect(extract_from_results(result, :path)).to be_empty
      end

      it "matches against the article's user's username", :aggregate_failures do
        article_user = article.user
        article_user.update_columns(username: "fridaysunday")

        result = described_class.search_documents(user, term: "Frida")
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "Sat")
        expect(extract_from_results(result, :path)).to be_empty
      end
    end

    context "when searching for a term and filtering by statuses" do
      it "selects items with the requested status belonging to articles matching the term", :aggregate_failures do
        article.update_columns(body_markdown: "Life of the party")

        result = described_class.search_documents(user, term: "part", statuses: %i[valid])
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "part", statuses: %i[archived])
        expect(extract_from_results(result, :path)).to be_empty

        result = described_class.search_documents(user, term: "fiesta", statuses: %i[valid])
        expect(extract_from_results(result, :path)).to be_empty
      end
    end

    context "when searching for a term and filtering by tags" do
      it "selects items with the requested status belonging to articles matching the term", :aggregate_failures do
        article.update_columns(body_markdown: "Life of the party", cached_tag_list: "javascript, beginners, ruby")

        result = described_class.search_documents(user, term: "part", tags: %i[javascript])
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "part", tags: %i[python])
        expect(extract_from_results(result, :path)).to be_empty

        result = described_class.search_documents(user, term: "fiesta", tags: %i[javascript])
        expect(extract_from_results(result, :path)).to be_empty
      end
    end

    context "when searching for a term and filtering by statuses and tags" do
      it "selects items with the requested status belonging to articles matching the term", :aggregate_failures do
        article.update_columns(body_markdown: "Life of the party", cached_tag_list: "javascript, beginners, ruby")

        result = described_class.search_documents(user, term: "part", statuses: %i[valid], tags: %i[javascript])
        expect(extract_from_results(result, :path)).to include(article.path)

        result = described_class.search_documents(user, term: "part", statuses: %i[archived], tags: %i[javascript])
        expect(extract_from_results(result, :path)).to be_empty

        result = described_class.search_documents(user, term: "part", statuses: %i[valid], tags: %i[python])
        expect(extract_from_results(result, :path)).to be_empty
      end
    end

    context "when paginating" do
      let(:articles) { create_list(:article, 2) }

      before do
        articles.each { |article| create(:reaction, category: :readinglist, reactable: article, user: user) }
      end

      it "returns the total count of the articles pre-pagination" do
        result = described_class.search_documents(user, page: 1, per_page: 1)
        expect(result[:total]).to eq(user.reactions.readinglist.count)
      end

      it "returns no items when out of pagination bounds" do
        result = described_class.search_documents(user, page: 99)
        expect(result[:items]).to be_empty
      end

      it "returns paginated items", :aggregate_failures do
        result = described_class.search_documents(user, page: 1, per_page: 1)
        expect(result[:items].length).to eq(1)

        result = described_class.search_documents(user, page: 2, per_page: 1)
        expect(result[:items].length).to eq(1)
      end
    end
  end
end
