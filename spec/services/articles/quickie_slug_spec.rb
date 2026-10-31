require "rails_helper"

RSpec.describe Articles::QuickieSlug, type: :service do
  let(:user) { create(:user) }
  let(:suffix) { "[0-9a-p]{1,4}" }

  def slug_for(title, user_id: user.id)
    described_class.call(title, user_id: user_id)
  end

  it "keeps only the first few meaningful words" do
    slug = slug_for("Just shipped the new dashboard redesign for everyone on the team today")

    expect(slug).to match(/\Ajust-shipped-new-dashboard-redesign-#{suffix}\z/)
  end

  it "skips stop words but falls back to them when nothing else is left" do
    expect(slug_for("To be or not to be")).to match(/\Anot-#{suffix}\z/)
    expect(slug_for("to be or")).to match(/\Ato-be-or-#{suffix}\z/)
  end

  it "keeps the readable part within the maximum length" do
    slug = slug_for("Internationalization infrastructure documentation configuration")
    base = slug.rpartition("-").first

    expect(base.length).to be <= described_class::MAX_LENGTH
    expect(slug).to match(/\Ainternationalization-infrastructure-documentation-#{suffix}\z/)
  end

  it "cuts a single oversized word" do
    slug = slug_for("a" * 80)

    expect(slug.rpartition("-").first.length).to eq(described_class::MAX_LENGTH)
  end

  it "ignores URLs and markdown formatting characters" do
    slug = slug_for("**Big** news: https://example.com/some/very/long/path?x=1 [read](https://dev.to) _now_")

    expect(slug).to match(/\Abig-news-read-#{suffix}\z/)
  end

  it "transliterates non-Latin text" do
    expect(slug_for("Привет мир")).to match(/\Aprivet-mir-#{suffix}\z/)
  end

  it "falls back to a generic word when the title has nothing sluggable" do
    expect(slug_for("🎉🎉🎉")).to match(/\Aquickie-#{suffix}\z/)
    expect(slug_for("https://example.com")).to match(/\Aquickie-#{suffix}\z/)
  end

  it "only produces characters allowed by the slug validation" do
    expect(slug_for("Héllo, wörld! It's 100% fun_time")).to match(/\A[0-9a-z\-_]+\z/)
  end

  it "re-rolls the suffix when the author already has that slug" do
    generator = described_class.new("same words", user_id: user.id)
    allow(generator).to receive(:taken?).and_return(true, true, false)
    allow(described_class).to receive(:new).and_return(generator)

    expect(slug_for("same words")).to match(/\Asame-words-#{suffix}\z/)
    expect(generator).to have_received(:taken?).exactly(3).times
  end

  it "checks the database for an existing slug of the same author" do
    create(:article, user: user, slug: "same-words-0")

    expect(described_class.new("x", user_id: user.id).send(:taken?, "same-words-0")).to be(true)
    expect(described_class.new("x", user_id: create(:user).id).send(:taken?, "same-words-0")).to be(false)
  end

  it "falls back to a longer random suffix after repeated collisions" do
    generator = described_class.new("same words", user_id: user.id)
    allow(generator).to receive(:taken?).and_return(true, true, true, true, true)
    allow(described_class).to receive(:new).and_return(generator)

    expect(slug_for("same words")).to match(/\Asame-words-[0-9a-f]{8}\z/)
  end
end
