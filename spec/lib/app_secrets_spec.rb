require "rails_helper"

RSpec.describe AppSecrets, type: :lib do
  let(:namespace) { "secret-namespace" }
  let(:key) { "SECRET_KEY" }
  let(:secret_stub) { instance_double("Vault::Kv", data: { value: 1 }) }
  let(:vault_stub) { instance_double("Vault::Kv", read: secret_stub) }

  before do
    allow(described_class).to receive(:namespace).and_return(namespace)
    allow(Vault).to receive(:kv) { vault_stub }
    allow(ApplicationConfig).to receive(:[])
    allow(ENV).to receive(:[])
  end

  describe "[]" do
    context "with VAULT_TOKEN present" do
      before do
        allow(ENV).to receive(:[]).with("VAULT_TOKEN").and_return("present")
      end

      it "fetches keys from Vault" do
        described_class[key]
        expect(Vault).to have_received(:kv).with(namespace)
        expect(vault_stub).to have_received(:read).with(key)
      end

      it "fetches keys from ApplicationConfig if not in Vault" do
        allow(Vault).to receive(:kv) { instance_double("Vault::Kv", read: nil) }

        described_class[key]
        expect(ApplicationConfig).to have_received(:[]).with(key)
      end

      it "fetches keys from ApplicationConfig if Vault raises an error" do
        allow(Vault).to receive(:kv).and_raise(Vault::VaultError)

        described_class[key]
        expect(ApplicationConfig).to have_received(:[]).with(key)
      end
    end

    context "without VAULT_TOKEN present" do
      before { allow(ApplicationConfig).to receive(:[]).with("VAULT_TOKEN").and_return("") }

      it "fetches keys from ApplicationConfig" do
        allow(Vault).to receive(:kv) { instance_double("Vault::Kv", read: nil) }

        described_class[key]
        expect(ApplicationConfig).to have_received(:[]).with(key)
        expect(Vault).not_to have_received(:kv).with(namespace)
      end
    end
  end

  describe "[]=" do
    it "sets keys in Vault" do
      write_stub = instance_double("Vault::Kv", write: nil)
      allow(Vault).to receive(:kv) { write_stub }

      described_class[key] = "secret-value"
      expect(write_stub).to have_received(:write).with(key, value: "secret-value")
    end
  end
end
