RSpec.shared_examples "Taggable" do
  let(:model) { described_class } # the class that includes the concern
  object = described_class.name.underscore.to_sym

  describe ".cached_tagged_with" do
    it "can search for a single tag" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      articles = described_class.cached_tagged_with("includeme")

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme").to_a
    end

    it "can search for a single tag when given a symbol" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      articles = described_class.cached_tagged_with(:includeme)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme").to_a)
    end

    it "can search for a single tag when given a Tag object" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      tag = Tag.find_by(name: :includeme)

      articles = described_class.cached_tagged_with(tag)

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme").to_a
    end

    it "can search among multiple tags" do
      included = [
        create(object, tag_list: "omg, wtf"),
        create(object, tag_list: "omg, lol"),
      ]
      excluded = create(object, tag_list: "nope, excluded")

      articles = described_class.cached_tagged_with("omg")

      expect(articles).to include(*included)
      expect(articles).not_to include excluded
      expect(articles.to_a).to include(*described_class.tagged_with("omg").to_a)
    end

    it "can search for multiple tags" do
      included = create(object, tag_list: "includeme, please, lol")
      excluded_partial_match = create(object, tag_list: "excluded, please")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      articles = described_class.cached_tagged_with(%w[includeme please])

      expect(articles).to include included
      expect(articles).not_to include excluded_partial_match
      expect(articles).not_to include excluded_no_match
      expect(articles.to_a).to eq described_class.tagged_with(%w[includeme please]).to_a
    end

    it "can search for multiple tags passed as an array of symbols" do
      included = create(object, tag_list: "includeme, please, lol")
      excluded_partial_match = create(object, tag_list: "excluded, please")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      articles = described_class.cached_tagged_with(%i[includeme please])

      expect(articles).to include(included)
      expect(articles).not_to include(excluded_partial_match)
      expect(articles).not_to include(excluded_no_match)
      expect(articles.to_a).to eq(described_class.tagged_with(%i[includeme please]).to_a)
    end

    it "can search for multiple tags passed as an array of Tag objects" do
      included = create(object, tag_list: "includeme, please, lol")
      excluded_partial_match = create(object, tag_list: "excluded, please")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      tags = Tag.where(name: %i[includeme please]).to_a
      articles = described_class.cached_tagged_with(tags)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded_partial_match)
      expect(articles).not_to include(excluded_no_match)
      expect(articles.to_a).to eq(described_class.tagged_with(%i[includeme please]).to_a)
    end
  end

  describe ".cached_tagged_with_any" do
    it "can search for a single tag" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      articles = described_class.cached_tagged_with_any("includeme")

      expect(articles).to include included
      expect(articles).not_to include excluded
      expect(articles.to_a).to eq described_class.tagged_with("includeme", any: true).to_a
    end

    it "can search for a single tag when given a symbol" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      articles = described_class.cached_tagged_with_any(:includeme)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme", any: true).to_a)
    end

    it "can search for a single tag when given a Tag object" do
      included = create(object, tag_list: "includeme")
      excluded = create(object, tag_list: "lol, nope")

      tag = Tag.find_by(name: :includeme)
      articles = described_class.cached_tagged_with_any(tag)

      expect(articles).to include(included)
      expect(articles).not_to include(excluded)
      expect(articles.to_a).to eq(described_class.tagged_with("includeme", any: true).to_a)
    end

    it "can search among multiple tags" do
      included = [
        create(object, tag_list: "omg, wtf"),
        create(object, tag_list: "omg, lol"),
      ]
      excluded = create(object, tag_list: "nope, excluded")

      articles = described_class.cached_tagged_with_any("omg")
      expected = described_class.tagged_with("omg", any: true).to_a

      expect(articles).to include(*included)
      expect(articles).not_to include excluded
      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags" do
      included = create(object, tag_list: "includeme, please, lol")
      included_partial_match = create(object, tag_list: "includeme, omg")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      articles = described_class.cached_tagged_with_any(%w[includeme please])
      expected = described_class.tagged_with(%w[includeme please], any: true).to_a

      expect(articles).to include included
      expect(articles).to include included_partial_match
      expect(articles).not_to include excluded_no_match

      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags when given an array of symbols" do
      included = create(object, tag_list: "includeme, please, lol")
      included_partial_match = create(object, tag_list: "includeme, omg")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      articles = described_class.cached_tagged_with_any(%i[includeme please])
      expected = described_class.tagged_with(%i[includeme please], any: true).to_a

      expect(articles).to include(included)
      expect(articles).to include(included_partial_match)
      expect(articles).not_to include(excluded_no_match)

      expect(articles.to_a).to include(*expected)
    end

    it "can search for multiple tags when given an array of Tag objects" do
      included = create(object, tag_list: "includeme, please, lol")
      included_partial_match = create(object, tag_list: "includeme, omg")
      excluded_no_match = create(object, tag_list: "excluded, omg")

      tags = Tag.where(name: %i[includeme please]).to_a
      articles = described_class.cached_tagged_with_any(tags)
      expected = described_class.tagged_with(%i[includeme please], any: true).to_a

      expect(articles).to include(included)
      expect(articles).to include(included_partial_match)
      expect(articles).not_to include(excluded_no_match)

      expect(articles.to_a).to include(*expected)
    end
  end

  describe ".not_cached_tagged_with_any" do
    it "can exclude multiple tags when given an array of strings" do
      included = create(object, tag_list: "includeme")
      excluded1 = create(object, tag_list: "includeme, lol")
      excluded2 = create(object, tag_list: "includeme, omg")

      articles = described_class
        .cached_tagged_with_any("includeme")
        .not_cached_tagged_with_any(%w[lol omg])

      expect(articles).to include included
      expect(articles).not_to include excluded1
      expect(articles).not_to include excluded2
    end
  end
end
