require "rails_helper"

RSpec.describe Settings::Base, type: :model do
  before do
    test_settings = Class.new(described_class) do
      field :host, default: "http://example.com", validates: { presence: true }
      field :mailer_provider,
            default: "smtp",
            validates: { presence: true, inclusion: { in: %w[smtp sendmail sendgrid] } }
      field :user_limits,
            type: :integer,
            default: 1,
            validates: { presence: true, format: { with: /\d+/, message: "must be numbers" } }
      field :admin_emails, type: :array, default: %w[admin@example.com]
      field :tips, type: :array, separator: /\n+/
      field :default_tags, type: :array, separator: /[\s,]+/
      field :captcha_enable, type: :boolean, default: true
      field :smtp_settings,
            type: :hash,
            default: {
              host: "example.com",
              username: "test@example.com",
              password: "123456"
            }
      field :omniauth_github_options,
            type: :hash,
            default: {
              client_id: "the-client-id",
              client_secret: "the-client-secret"
            }
      field :float_item, type: :float, default: 7
      field :big_decimal_item, type: :big_decimal, default: 9
      field :default_value_with_block, type: :integer, default: -> { 1 + 1 }
    end
    stub_const("TestSettings", test_settings)
  end

  context "when using protectec field names" do
    it "does not allow 'var' as field name" do
      expect do
        Class.new(Settings::Base) { field :var }
      end.to raise_error(Settings::Base::ProcetedKeyError)
    end

    it "does not allow 'value' as field name" do
      expect do
        Class.new(Settings::Base) { field :value }
      end.to raise_error(Settings::Base::ProcetedKeyError)
    end
  end

  describe ".get_field" do
    it "returns an empty hash for invalid keys" do
      expect(TestSettings.get_field("invalid")).to eq({})
    end

    it "returns the configuration for valid keys" do
      expect(TestSettings.get_field("host"))
        .to eq({ key: "host", default: "http://example.com", type: :string })
    end
  end

  # TODO: port more specs
end
