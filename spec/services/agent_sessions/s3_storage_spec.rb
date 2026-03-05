require "rails_helper"

RSpec.describe AgentSessions::S3Storage do
  describe ".generate_key" do
    it "generates a key with the correct prefix and user ID" do
      key = described_class.generate_key(42)
      expect(key).to match(%r{\Aagent_sessions/42/[0-9a-f-]+\.jsonl\z})
    end

    it "generates a key with the file extension from filename" do
      key = described_class.generate_key(42, "session.json")
      expect(key).to match(%r{\Aagent_sessions/42/[0-9a-f-]+\.json\z})
    end

    it "generates unique keys" do
      keys = Array.new(10) { described_class.generate_key(1) }
      expect(keys.uniq.size).to eq(10)
    end
  end

  describe ".enabled?" do
    it "returns true when AWS credentials are configured" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")

      expect(described_class.enabled?).to be true
    end

    it "returns false when AWS_ID is missing" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")

      expect(described_class.enabled?).to be false
    end

    it "returns false when AWS_BUCKET_NAME is missing" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return(nil)

      expect(described_class.enabled?).to be false
    end
  end

  describe ".presigned_put_url" do
    it "calls fog storage with correct arguments" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config

      expect(fog_storage).to receive(:put_object_url)
        .with("test-bucket", "agent_sessions/1/test.jsonl", 900, "Content-Type" => "application/x-jsonlines")
        .and_return("https://s3.example.com/presigned-put")

      reset_storage

      url = described_class.presigned_put_url("agent_sessions/1/test.jsonl")
      expect(url).to eq("https://s3.example.com/presigned-put")

      reset_storage
    end
  end

  describe ".presigned_get_url" do
    it "calls fog storage with correct arguments" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config

      expect(fog_storage).to receive(:get_object_url)
        .with("test-bucket", "agent_sessions/1/test.jsonl", 900)
        .and_return("https://s3.example.com/presigned-get")

      reset_storage

      url = described_class.presigned_get_url("agent_sessions/1/test.jsonl")
      expect(url).to eq("https://s3.example.com/presigned-get")

      reset_storage
    end
  end

  describe ".delete" do
    it "calls fog storage delete_object" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config

      expect(fog_storage).to receive(:delete_object)
        .with("test-bucket", "agent_sessions/1/test.jsonl")

      reset_storage
      described_class.delete("agent_sessions/1/test.jsonl")
      reset_storage
    end

    it "does not raise on Excon errors" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config

      allow(fog_storage).to receive(:delete_object).and_raise(Excon::Error.new("not found"))

      reset_storage
      expect { described_class.delete("bad-key") }.not_to raise_error
      reset_storage
    end
  end

  private

  def stub_aws_config
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
    allow(ApplicationConfig).to receive(:[]).with("AWS_SECRET").and_return("test-secret")
    allow(ApplicationConfig).to receive(:[]).with("AWS_UPLOAD_REGION").and_return("us-east-1")
    allow(ApplicationConfig).to receive(:[]).with("AWS_DEFAULT_REGION").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
  end

  def reset_storage
    described_class.instance_variable_set(:@storage, nil)
  end
end
