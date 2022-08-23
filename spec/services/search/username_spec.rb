require "rails_helper"

RSpec.describe Search::Username, type: :service do
  def search(term, **options)
    described_class.search_documents(term, **options)
  end

  it "defines necessary constants" do
    expect(described_class::ATTRIBUTES).not_to be_nil
    expect(described_class::MAX_RESULTS).not_to be_nil
  end

  describe "::search_documents without context" do
    it "returns data in the expected format" do
      user = create(:user)

      result = described_class.search_documents(user.username)

      expect(result.first.keys).to match_array(
        %i[id name profile_image_90 username],
      )
    end

    it "does not find a user given the wrong search term" do
      create(:user, username: "joao", name: "joao")

      expect(described_class.search_documents("foobar")).to be_empty
    end

    it "finds a user by their username" do
      user = create(:user)

      expect(described_class.search_documents(user.username)).to be_present
    end

    it "finds a user by a partial username" do
      user = create(:user)

      expect(described_class.search_documents(user.username.first(1))).to be_present
    end

    it "finds a user by their name" do
      user = create(:user)

      expect(described_class.search_documents(user.name)).to be_present
    end

    it "finds a user by a partial name" do
      user = create(:user)

      expect(described_class.search_documents(user.name.first(3))).to be_present
    end

    it "finds a user if their name contains quotes", :aggregate_failures do
      user = create(:user, name: "McNamara O'Hara")
      expect(described_class.search_documents(user.name)).to be_present

      user = create(:user, name: 'McNamara O"Hara')
      expect(described_class.search_documents(user.name)).to be_present
    end

    it "finds multiple users whose names have common parts", :aggregate_failures do
      alex = create(:user, username: "alex")
      alexsmith = create(:user, name: "alexsmith")
      rhymes = create(:user, username: "rhymes", name: "Non-matching Name")

      result = described_class.search_documents("ale")
      usernames = result.pluck(:username)

      expect(usernames).to include(alex.username)
      expect(usernames).to include(alexsmith.username)
      expect(usernames).not_to include(rhymes.username)
    end

    it "limits the number of results to the value of MAX_RESULTS" do
      max_results = 1
      stub_const("#{described_class}::MAX_RESULTS", max_results)

      alex = create(:user, username: "alex")
      alexsmith = create(:user, username: "alexsmith")

      results = described_class.search_documents("alex")

      expect(results.size).to eq(max_results)
      expect([alex.username, alexsmith.username]).to include(results.first[:username])
    end

    it "sanitizes the input when given slashes" do
      expect(described_class.search_documents("\\")).to eq([])
    end
  end

  describe "::search_documents with context" do
    let(:article) { create :article, user: author }
    let(:author) { create :user, name: "Person A", username: "author" }
    let(:commenter) { create :user, name: "Person B", username: "commentator" }

    before do
      create :comment, user: commenter, commentable: article
    end

    it "returns data in the expected format" do
      result = search("author", context: article)

      expect(result.first.keys).to match_array(
        %i[id name profile_image_90 username],
      )
    end

    it "does not find a user given the wrong search term" do
      expect(search("foobar", context: article)).to be_empty
    end

    it "finds a user by their username" do
      expect(search("author", context: article)).to be_present
    end

    it "finds a user by a partial username" do
      expect(search("comment", context: article)).to be_present
    end

    it "finds a user by their name" do
      expect(search("Person A", context: article)).to be_present
    end

    it "finds a user by a partial name" do
      expect(search("Per", context: article)).to be_present
    end

    it "finds multiple users whose names have common parts", :aggregate_failures do
      rhymes = create(:user, username: "rhymes", name: "Non-matching Name")

      result = search("Per", context: article)
      usernames = result.pluck(:username)

      expect(usernames).to include(author.username)
      expect(usernames).to include(commenter.username)
      expect(usernames).not_to include(rhymes.username)
    end

    it "limits the number of results to the value of MAX_RESULTS" do
      max_results = 1
      stub_const("#{described_class}::MAX_RESULTS", max_results)

      results = search("Per", context: article)

      expect(results.size).to eq(max_results)
    end

    it "sanitizes the input when given slashes" do
      expect(search("\\", context: article)).to eq([])
    end

    it "ranks author higher than commenter" do
      results = search("Per", context: article)
      expect(results.pluck(:username)).to contain_exactly(*%w[author commentator])
    end

    it "ranks unrelated user lower" do
      create :user, username: "unrelated", name: "Person C"

      results = search("Per", context: article)

      expect(results.pluck(:username)).to contain_exactly(*%w[author commentator unrelated])
    end

    it "does not have authorship ranking for PodcastEpisode (yet)" do
      pod_ep = create :podcast_episode

      results = search("Per", context: pod_ep)

      expect(results.pluck(:username)).not_to be_empty
    end
  end
end
