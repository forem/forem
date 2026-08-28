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

    it "falls back to .jsonl for disallowed extensions" do
      key = described_class.generate_key(42, "evil.exe")
      expect(key).to match(%r{\Aagent_sessions/42/[0-9a-f-]+\.jsonl\z})
    end

    it "falls back to .jsonl for path traversal attempts" do
      key = described_class.generate_key(42, "../../etc/passwd")
      expect(key).to match(%r{\Aagent_sessions/42/[0-9a-f-]+\.jsonl\z})
    end

    it "generates unique keys" do
      keys = Array.new(10) { described_class.generate_key(1) }
      expect(keys.uniq.size).to eq(10)
    end
  end

  describe ".valid_key_for_user?" do
    let(:uuid) { SecureRandom.uuid }

    it "returns true for a valid user key with .jsonl extension" do
      key = "agent_sessions/42/#{uuid}.jsonl"
      expect(described_class.valid_key_for_user?(key, 42)).to be true
    end

    it "returns true for a valid user key with .json extension" do
      key = "agent_sessions/42/#{uuid}.json"
      expect(described_class.valid_key_for_user?(key, 42)).to be true
    end

    it "returns false for a key belonging to a different user" do
      key = "agent_sessions/99/#{uuid}.jsonl"
      expect(described_class.valid_key_for_user?(key, 42)).to be false
    end

    it "returns false for an invalid extension" do
      key = "agent_sessions/42/#{uuid}.png"
      expect(described_class.valid_key_for_user?(key, 42)).to be false
    end

    it "returns false for path traversal attempts" do
      key = "agent_sessions/42/../../uploads/avatar.png"
      expect(described_class.valid_key_for_user?(key, 42)).to be false
    end

    it "returns false for blank key or user_id" do
      expect(described_class.valid_key_for_user?("", 42)).to be false
      expect(described_class.valid_key_for_user?("agent_sessions/42/#{uuid}.jsonl", nil)).to be false
    end
  end

  describe ".enabled?" do
    it "returns true when AWS credentials are configured" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")

      expect(described_class.enabled?).to be true
    end

    it "returns true when AWS_AGENT_SESSIONS_BUCKET_NAME is configured" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return("dedicated-bucket")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return(nil)

      expect(described_class.enabled?).to be true
    end

    it "returns false when AWS_ID is missing" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")

      expect(described_class.enabled?).to be false
    end

    it "returns false when both buckets are missing" do
      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("test-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return(nil)

      expect(described_class.enabled?).to be false
    end
  end

  describe ".presigned_put_url" do
    it "calls fog storage with private ACL and correct arguments" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config
      allow(fog_storage).to receive(:put_object_url).and_return("https://s3.example.com/presigned-put")

      reset_storage

      url = described_class.presigned_put_url("agent_sessions/1/test.jsonl")
      expect(url).to eq("https://s3.example.com/presigned-put")
      expect(fog_storage).to have_received(:put_object_url)
        .with("test-bucket", "agent_sessions/1/test.jsonl",
              a_value_between(Time.now.to_i + 895, Time.now.to_i + 905),
              "Content-Type" => "application/x-jsonlines",
              "x-amz-acl" => "private")

      reset_storage
    end

    it "uses AWS_AGENT_SESSIONS_BUCKET_NAME when provided" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config
      allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return("dedicated-bucket")
      allow(fog_storage).to receive(:put_object_url).and_return("https://s3.example.com/presigned-put")

      reset_storage

      url = described_class.presigned_put_url("agent_sessions/1/test.jsonl")
      expect(url).to eq("https://s3.example.com/presigned-put")
      expect(fog_storage).to have_received(:put_object_url)
        .with("dedicated-bucket", "agent_sessions/1/test.jsonl",
              a_value_between(Time.now.to_i + 895, Time.now.to_i + 905),
              "Content-Type" => "application/x-jsonlines",
              "x-amz-acl" => "private")

      reset_storage
    end
  end

  describe ".presigned_get_url" do
    it "calls fog storage with correct arguments" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config
      allow(fog_storage).to receive(:get_object_url).and_return("https://s3.example.com/presigned-get")

      reset_storage

      url = described_class.presigned_get_url("agent_sessions/1/test.jsonl")
      expect(url).to eq("https://s3.example.com/presigned-get")
      expect(fog_storage).to have_received(:get_object_url)
        .with("test-bucket", "agent_sessions/1/test.jsonl",
              a_value_between(Time.now.to_i + 895, Time.now.to_i + 905))

      reset_storage
    end
  end

  describe ".delete" do
    it "calls fog storage delete_object" do
      fog_storage = double("Fog::Storage") # rubocop:disable RSpec/VerifiedDoubles
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
      stub_aws_config
      allow(fog_storage).to receive(:delete_object)

      reset_storage
      described_class.delete("agent_sessions/1/test.jsonl")
      expect(fog_storage).to have_received(:delete_object)
        .with("test-bucket", "agent_sessions/1/test.jsonl")
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
    allow(ApplicationConfig).to receive(:[]).with("AWS_AGENT_SESSIONS_BUCKET_NAME").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
  end

  def reset_storage
    described_class.instance_variable_set(:@storage, nil)
  end
end
