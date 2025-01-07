require "rails_helper"

RSpec.describe Page do
  describe ".from_subforem" do
    let!(:page_subforem_1) { create(:page, subforem_id: 1) }
    let!(:page_subforem_2) { create(:page, subforem_id: 2) }
    let!(:page_no_subforem) { create(:page, subforem_id: nil) }

    after do
      # Clean up to avoid polluting other specs
      RequestStore.store[:subforem_id] = nil
    end

    context "when subforem_id is not explicitly passed" do
      before do
        # Setting RequestStore so scope can detect it
        RequestStore.store[:subforem_id] = 1
      end

      it "defaults to RequestStore.store[:subforem_id]" do
        expect(described_class.from_subforem).to contain_exactly(page_subforem_1, page_no_subforem)
      end
    end

    context "when subforem_id is explicitly passed" do
      it "uses the passed subforem_id" do
        expect(described_class.from_subforem(2)).to contain_exactly(page_subforem_2, page_no_subforem)
      end
    end

    context "when RequestStore.store[:subforem_id] is nil" do
      it "returns records where subforem_id is nil if no argument is passed" do
        # subforem_id in store remains nil by default here
        expect(described_class.from_subforem).to contain_exactly(page_no_subforem)
      end
    end
  end

  describe ".render_safe_html_for" do
    let(:slug) { "the-given-slug" }

    context "when no matching slug in Page database" do
      specify { expect { |b| described_class.render_safe_html_for(slug: slug, &b) }.to yield_control }
    end

    context "when no matching slug and the caller didn't pass a block" do
      # Instead of raising an exception we could "silently" do nothing.  That too might be
      # reasonable.  But this seems like a good enough test.
      it "raises an exception" do
        expect { described_class.render_safe_html_for(slug: slug) }.to raise_error(LocalJumpError)
      end
    end

    context "when there's a matching slug" do
      subject(:rendered_html) { described_class.render_safe_html_for(slug: page.slug) }

      let!(:page) { create(:page, slug: "the-given-slug") }

      it { is_expected.to be_html_safe }

      it "returns the html safe version of the processed_html" do
        expect(rendered_html).to eq(page.processed_html)
      end

      specify { expect { |b| described_class.render_safe_html_for(slug: slug, &b) }.not_to yield_control }
    end
  end

  describe "#validations" do
    it "requires either body_markdown, body_html, body_json or body_css" do
      page = build(:page)
      page.body_html = nil
      page.body_markdown = nil
      page.body_json = nil
      page.body_css = nil
      expect(page).not_to be_valid
    end

    it "takes organization slug into account" do
      create(:organization, slug: "benandfriends")
      page = build(:page, slug: "benandfriends")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes podcast slug into account" do
      create(:podcast, slug: "benmeetsworld")
      page = build(:page, slug: "benmeetsworld")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes user username into account" do
      create(:user, username: "bennybenben")
      page = build(:page, slug: "bennybenben")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes sitemap into account" do
      page = build(:page, slug: "sitemap-hey")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "circumnavigates ReservedWords check" do
      page = build(:page, slug: "code-of-conduct")
      expect(page).to be_valid
    end

    it "allows / in slug" do
      page = build(:page, slug: "heyhey/hey")
      expect(page).to be_valid
    end

    it "disallows 6+ directories via /" do
      page = build(:page, slug: "heyhey/hey/hey/hey/hey/hey/hey")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("subdirectories")).to be true
    end
  end

  context "when callbacks are triggered before save" do
    let(:page) { create(:page) }

    describe "#processed_html" do
      it "accepts body markdown and turns it into html" do
        page.update(body_markdown: "Hello `heyhey`")
        expect(page.processed_html).to include("<code>")
      end

      it "accepts body html without changing it" do
        html = "Hello `heyhey`"
        page.update(body_html: html, body_markdown: "")
        expect(page.processed_html).to eq(html)
      end
    end
  end

  context "when callbacks are triggered after commit" do
    let(:page) { create(:page) }

    it "triggers cache busting on save" do
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: [page.slug]) do
        page.save
      end
    end

    it "ensures only one page can be a landing page on create" do
      p1 = create(:page, landing_page: true)
      create(:page, landing_page: true)

      expect(p1.reload.landing_page).to be(false)
    end

    it "ensures only one page can be a landing page on update" do
      p1 = create(:page, landing_page: true)
      p2 = create(:page, landing_page: false)

      p2.update(landing_page: true)

      expect(p1.reload.landing_page).to be(false)
    end
  end
end
