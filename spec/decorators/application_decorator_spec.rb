require "rails_helper"

RSpec.describe ApplicationDecorator, type: :decorator do
  describe "#object" do
    it "exposes the decorated object" do
      obj = Object.new
      expect(described_class.new(obj).object).to be(obj)
    end
  end

  describe "#class_name" do
    it "delegates to the underlying object" do
      obj = User.new
      decorated = described_class.new(obj)
      expect(decorated.class_name).to eq(obj.class_name)
    end
  end

  describe "#decorate" do
    it "returns itself" do
      obj = User.new
      decorated = described_class.new(obj)

      expect(decorated.object_id).to eq(decorated.decorate.object_id)
    end
  end

  describe "#decorated?" do
    it "returns true" do
      obj = Object.new
      expect(described_class.new(obj).decorated?).to be(true)
    end
  end

  # as ApplicationDecorator is an abstract class, some tests also use an actual decorator
  describe ".decorate_collection" do
    before do
      create(:article, approved: true)
    end

    it "receives an ActiveRecord relation and returns an array of decorated records" do
      relation = Article.approved

      decorated_collection = described_class.decorate_collection(relation)
      expect(decorated_collection.map(&:class)).to eq([ArticleDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end

    it "receives an array and returns an array of decorated records" do
      relation = Article.approved

      decorated_collection = described_class.decorate_collection(relation.to_a)
      expect(decorated_collection.map(&:class)).to eq([ArticleDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end
  end

  describe ".type_identifier" do
    it "returns the class downcased" do
      decorated_article = Article.new.decorate
      expect(decorated_article.type_identifier).to eq("article")

      decorated_user = User.new.decorate
      expect(decorated_user.type_identifier).to eq("user")

      decorated_organization = Organization.new.decorate
      expect(decorated_organization.type_identifier).to eq("organization")
    end
  end
end
