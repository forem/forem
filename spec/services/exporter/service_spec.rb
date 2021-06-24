require "rails_helper"
require "zip"

RSpec.describe Exporter::Service, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:other_user) { create(:user) }
  let(:other_user_article) { create(:article, user: other_user) }

  before do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
  end

  after do
    ApplicationMailer.deliveries.clear
  end

  def valid_instance(user)
    described_class.new(user)
  end

  def extract_zipped_exports(buffer)
    exports = {}

    buffer.rewind
    Zip::InputStream.open(buffer) do |stream|
      loop do
        entry = stream.get_next_entry
        break if entry.blank?

        exports[entry.name] = stream.read
      end
    end

    exports
  end

  describe "EXPORTERS" do
    it "is a list of supported exporters" do
      expect(described_class::EXPORTERS).to eq([Exporter::Articles, Exporter::Comments])
    end
  end

  describe "#initialize" do
    it "accepts a user" do
      service = valid_instance(user)
      expect(service.user).to be(user)
    end
  end

  describe "#export" do
    it "exports a zip file with files" do
      service = valid_instance(article.user)
      zipped_exports = service.export(article.user.email)
      exports = extract_zipped_exports(zipped_exports)
      expect(exports.keys).to eq(["articles.json", "comments.json"])
    end

    it "passes configuration to an exporter" do
      service = valid_instance(article.user)
      zipped_exports = service.export(article.user.email, config: { articles: { slug: article.slug } })
      exports = extract_zipped_exports(zipped_exports)
      expect(exports.length).to eq(described_class::EXPORTERS.size)
    end

    it "fetches the passed config" do
      service = valid_instance(article.user)
      config = double
      allow(config).to receive(:fetch).with(:articles, {}).and_return(slug: article.slug)
      allow(config).to receive(:fetch).with(:comments, {}).and_return({})
      service.export(article.user.email, config: config)
      expect(config).to have_received(:fetch).with(:articles, {})
    end

    context "when emailing the user" do
      it "delivers one email" do
        service = valid_instance(article.user)
        ApplicationMailer.deliveries.clear
        service.export(article.user.email)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it "delivers one email to the user's email" do
        service = valid_instance(article.user)
        service.export(article.user.email)
        expect(ActionMailer::Base.deliveries.last.to.first).to eq article.user.email
      end

      it "delivers an email with the export" do
        service = valid_instance(article.user)
        zipped_export = service.export(article.user.email)
        attachment = ActionMailer::Base.deliveries.last.attachments[0].decoded

        exports = extract_zipped_exports(zipped_export)
        expect(exports).to eq(extract_zipped_exports(StringIO.new(attachment)))
      end
    end

    context "when emailing an admin" do
      it "delivers one email to the contact admin email" do
        admin_email = "admin@example.com"
        allow(ForemInstance).to receive(:email).and_return(admin_email)
        service = valid_instance(article.user)
        service.export(admin_email)
        expect(ActionMailer::Base.deliveries.last.to.first).to eq admin_email
      end
    end

    it "sets the requested flag as false" do
      service = valid_instance(article.user)
      service.export(article.user.email)
      expect(user.export_requested).to be(false)
    end

    it "sets the exported at datetime as the current one" do
      Timecop.freeze(Time.current) do
        service = valid_instance(article.user)
        service.export(article.user.email)
        expect(user.exported_at).to eq(Time.current)
      end
    end
  end
end
