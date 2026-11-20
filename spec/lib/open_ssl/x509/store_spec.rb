require "spec_helper"
require "json"
require "openssl"
require "excon"
require "httpclient"
require "stripe"
require_relative "../../../../config/initializers/tls_trust"

RSpec.describe OpenSSL::X509::Store do
  let(:fixtures) do
    JSON.parse(File.read(File.expand_path("../../../fixtures/files/emudhra_ca_certificates.json", __dir__)))
  end
  let(:anchors) { fixtures.fetch("anchors").map { |entry| OpenSSL::X509::Certificate.new(entry.fetch("pem")) } }
  let(:issuers) { fixtures.fetch("issuers").map { |entry| OpenSSL::X509::Certificate.new(entry.fetch("pem")) } }
  let(:intermediates) do
    fixtures.fetch("intermediates").map { |entry| OpenSSL::X509::Certificate.new(entry.fetch("pem")) }
  end
  let(:trusted_root) do
    File.read(Excon::DEFAULT_CA_FILE).scan(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m)
      .map { |pem| OpenSSL::X509::Certificate.new(pem) }
      .detect { |certificate| certificate.subject.to_s.include?("CN=DigiCert Global Root G2") }
  end

  shared_examples "a corrected CA store" do
    it "retains an unaffected trusted root" do
      expect(store.verify(trusted_root)).to be(true)
    end

    it "rejects both affected trust anchors and intermediate chain variants", :aggregate_failures do
      (anchors + intermediates).each do |certificate|
        expect(store.verify(certificate, issuers)).to be(false), certificate.subject.to_s
      end
    end
  end

  it "uses authentic public certificates for both affected chain paths", :aggregate_failures do
    fixtures.values.flatten.each do |entry|
      certificate = OpenSSL::X509::Certificate.new(entry.fetch("pem"))
      expect(OpenSSL::Digest::SHA256.hexdigest(certificate.to_der).upcase).to eq(entry.fetch("sha256"))
    end

    original_store = described_class.new
    anchors.each { |certificate| original_store.add_cert(certificate) }
    intermediates.each do |certificate|
      expect(original_store.verify(certificate, issuers)).to be(true)
    end
  end

  context "with HTTPClient" do
    let(:ssl_config) { HTTPClient.new.ssl_config }
    let(:ssl_context) { OpenSSL::SSL::SSLContext.new.tap { |context| ssl_config.set_context(context) } }
    let(:store) { ssl_context.cert_store }

    include_examples "a corrected CA store"

    it "keeps peer verification and the default compromised-key restriction", :aggregate_failures do
      expect(ssl_context.verify_mode & OpenSSL::SSL::VERIFY_PEER).not_to eq(0)
      expect(ssl_config.verify_callback).to be_nil
      intermediates.each do |certificate|
        expect { ssl_config.check_peer_certificates([certificate]) }.to raise_error(OpenSSL::SSL::SSLError)
      end
      expect { ssl_config.check_peer_certificates([trusted_root]) }.not_to raise_error
    end
  end

  context "with Stripe" do
    let(:store) { Stripe.ca_store }

    include_examples "a corrected CA store"

    it "uses the maintained Excon bundle without opening a connection", :aggregate_failures do
      expect(Stripe.ca_bundle_path).to eq(Excon::DEFAULT_CA_FILE)
      connection = Stripe::ConnectionManager.new.__send__(:create_connection, URI("https://stripe.example.test"))
      expect(connection.cert_store).to equal(store)
      expect(connection.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
      expect(connection.started?).to be(false)
    end
  end

  context "with Excon" do
    let(:connection) { Excon.new("https://offline.example.test") }
    let(:callback) { connection.data.fetch(:ssl_verify_callback) }
    let(:store) do
      described_class.new.tap do |certificate_store|
        certificate_store.add_file(Excon::DEFAULT_CA_FILE)
        certificate_store.verify_callback = callback
      end
    end

    include_examples "a corrected CA store"

    it "rejects compromised keys even when the inherited store trusts their issuers" do
      anchors.each { |certificate| store.add_cert(certificate) }
      intermediates.each do |certificate|
        expect(store.verify(certificate, issuers)).to be(false)
      end
    end

    it "preserves OpenSSL verification failures" do
      context = instance_double(OpenSSL::X509::StoreContext, current_cert: trusted_root)
      expect(callback.call(false, context)).to be(false)
    end

    it "preserves peer verification without replacing issuer selection", :aggregate_failures do
      expect(connection.data[:ssl_verify_peer]).to be(true)
      expect(connection.data[:ssl_cert_store]).to be_nil
      expect(connection.data[:ssl_ca_file]).to be_nil
      expect(connection.data[:ssl_ca_path]).to be_nil
    end

    it "preserves an explicit connection verification callback" do
      custom_callback = ->(preverified, _context) { preverified }
      custom_connection = Excon.new("https://offline.example.test", ssl_verify_callback: custom_callback)
      expect(custom_connection.data[:ssl_verify_callback]).to equal(custom_callback)
    end

    it "keeps a legitimate private CA trusted when supplied by the existing store" do
      key = OpenSSL::PKey::EC.generate("prime256v1")
      private_ca = OpenSSL::X509::Certificate.new
      private_ca.version = 2
      private_ca.serial = 1
      private_ca.subject = OpenSSL::X509::Name.parse("/CN=Private test CA")
      private_ca.issuer = private_ca.subject
      private_ca.public_key = key
      private_ca.not_before = Time.utc(2020, 1, 1)
      private_ca.not_after = Time.utc(2040, 1, 1)
      extension_factory = OpenSSL::X509::ExtensionFactory.new
      private_ca.add_extension(extension_factory.create_extension("basicConstraints", "CA:TRUE", true))
      private_ca.sign(key, OpenSSL::Digest.new("SHA256"))
      store.add_cert(private_ca)

      expect(store.verify(private_ca)).to be(true)
    end
  end
end
