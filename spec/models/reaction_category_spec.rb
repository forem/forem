require "rails_helper"

RSpec.describe ReactionCategory, type: :model do
  let(:attributes_hash) do
    {
      "slug" => "lol",
      "name" => "Laughing",
      "position" => 2,
      :published => true
    }
  end

  it "returns category object via [:slug]" do
    expect(described_class[:like]).to be_a(described_class)
    expect(described_class[:vomit].slug).to eq(:vomit)
    expect(described_class[:thumbsdown].name).to eq("Thumbsdown")
  end

  it "lists all category slugs" do
    expect(described_class.all_slugs).to contain_exactly(*%i[like unicorn readinglist hands thinking thumbsup
                                                             thumbsdown vomit])
  end

  it "lists public categories" do
    expect(described_class.public).to contain_exactly(*%i[like readinglist unicorn])
  end

  it "lists privileged categories" do
    expect(described_class.privileged).to contain_exactly(*%i[thumbsup thumbsdown vomit])
  end

  it "lists negative_privileged categories" do
    expect(described_class.negative_privileged).to contain_exactly(*%i[thumbsdown vomit])
  end

  it "initializes via an attributes hash" do
    attributes = attributes_hash

    initialized = described_class.new attributes
    expect(initialized.slug).to eq(:lol)
    expect(initialized.name).to eq("Laughing")
    expect(initialized.position).to eq(2)
    expect(initialized).to be_published
    expect(initialized).not_to be_privileged
  end

  it "name defaults to Slug" do
    slugged = described_class.new(slug: "my_name_is")
    expect(slugged.name).to eq("My Name Is")
  end

  it "score defaults to 1.0" do
    default = described_class.new
    expect(default.score.to_s).to eq("1.0")

    scored = described_class.new(score: 20.0)
    expect(scored.score.to_s).to eq("20.0")
  end

  it "privileged defaults to false" do
    default = described_class.new
    expect(default).not_to be_privileged

    privileged = described_class.new(privileged: true)
    expect(privileged).to be_privileged
  end

  it "published defaults to true" do
    default = described_class.new
    expect(default).to be_published

    unpublished = described_class.new(published: false)
    expect(unpublished).not_to be_published
  end

  it "position defaults to 99" do
    default = described_class.new
    expect(default.position).to eq(99)

    positioned = described_class.new(position: 4)
    expect(positioned.position).to eq(4)
  end

  it "is positive when score is above zero" do
    positive = described_class.new(score: 15.0)
    expect(positive).to be_positive

    negative = described_class.new(score: -1.0)
    expect(negative).not_to be_positive
  end

  it "is negative when score is below zero" do
    positive = described_class.new(score: 15.0)
    expect(positive).not_to be_negative

    negative = described_class.new(score: -1.0)
    expect(negative).to be_negative
  end

  it "is visible_to_public when non-privileged and public" do
    privileged = described_class.new(privileged: true)
    expect(privileged).not_to be_visible_to_public

    unpublished = described_class.new(published: false)
    expect(unpublished).not_to be_visible_to_public

    visible = described_class.new(privileged: false, published: true)
    expect(visible).to be_visible_to_public
  end
end
