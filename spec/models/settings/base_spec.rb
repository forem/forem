require "rails_helper"

RSpec.describe Settings::Base, type: :model do
  with_model :TestSetting, superclass: described_class do
    table do |t|
      t.string :var, null: false
      t.text :value, null: true
      t.timestamps
    end

    model do
      setting :host, default: "http://example.com", validates: { presence: true }
      setting :mailer_provider,
              default: "smtp",
              validates: { presence: true, inclusion: { in: %w[smtp sendmail sendgrid] } }
      setting :user_limits,
              type: :integer,
              default: 1,
              validates: { presence: true, format: { with: /\d+/, message: "must be numbers" } }
      setting :admin_emails, type: :array, default: %w[admin@example.com]
      setting :default_tags, type: :array, separator: /:/, default: []
      setting :captcha_enable, type: :boolean, default: false
      setting :smtp_settings,
              type: :hash,
              default: {
                host: "example.com",
                username: "test@example.com",
                password: "123456"
              }
      setting :float_item, type: :float, default: 7
      setting :big_decimal_item, type: :big_decimal, default: 9
      setting :default_value_with_block, type: :integer, default: -> { 1 + 1 }
    end
  end

  context "when using protected setting names" do
    it "does not allow 'var' as setting name" do
      expect do
        Class.new(Settings::Base) { setting :var }
      end.to raise_error(Settings::ProtectedKeyError, "Can't use 'var' as setting name")
    end

    it "does not allow 'value' as setting name" do
      expect do
        Class.new(Settings::Base) { setting :value }
      end.to raise_error(Settings::ProtectedKeyError, "Can't use 'value' as setting name")
    end
  end

  describe ".keys" do
    it "returns all the defined settings", :aggregate_failures do
      expect(TestSetting.keys.size).to eq 10
      expect(TestSetting.keys).to include("host")
      expect(TestSetting.keys).to include("default_value_with_block")
    end
  end

  describe ".get_setting" do
    it "returns an empty hash for invalid keys" do
      expect(TestSetting.get_setting("invalid")).to eq({})
    end

    it "returns the configuration for valid keys", :aggregate_failures do
      expect(TestSetting.get_setting("host"))
        .to eq({ key: "host", default: "http://example.com", type: :string })

      expect(TestSetting.get_setting("admin_emails"))
        .to eq({ key: "admin_emails", default: ["admin@example.com"], type: :array })
    end
  end

  describe "setters" do
    it "updates the setting's value" do
      expect { TestSetting.user_limits = 3 }
        .to change(TestSetting, :user_limits).from(1).to(3)
    end
  end

  describe "defaults" do
    it "returns static defaults" do
      expected = {
        host: "example.com",
        username: "test@example.com",
        password: "123456"
      }

      expect(TestSetting.smtp_settings).to eq(expected)
    end

    it "returns defaults calculated in a block" do
      expect(TestSetting.default_value_with_block).to eq 2
    end
  end

  describe "coercions" do
    context "when coercing booleans" do
      ["true", "1", 1].each do |value|
        it "coerces #{value.inspect} to true", :aggregate_failures do
          TestSetting.captcha_enable = false

          expect { TestSetting.captcha_enable = value }
            .to change(TestSetting, :captcha_enable).from(false).to(true)
        end
      end
    end

    context "when coercing arrays" do
      it "splits strings into arrays based on the specified seprator" do
        expect { TestSetting.default_tags = "test1:test2" }
          .to change(TestSetting, :default_tags)
          .from([]).to %w[test1 test2]
      end

      it "splits strings into arrays based on the default seprator if no separator is specified" do
        expect { TestSetting.admin_emails = "test1@example.com,test2@example.com" }
          .to change(TestSetting, :admin_emails)
          .from(["admin@example.com"]).to %w[test1@example.com test2@example.com]
      end
    end

    it "coerces values to integer" do
      TestSetting.user_limits = 3.0
      expect(TestSetting.user_limits).to eq 3
    end

    it "coerces values to floats" do
      TestSetting.float_item = 5
      expect(TestSetting.float_item).to eq 5.0
    end

    it "coerces values to big decimals" do
      TestSetting.big_decimal_item = 5
      expect(TestSetting.big_decimal_item).to be_an_instance_of(BigDecimal)
    end
  end

  describe "validations" do
    it "validates a value's presence", :aggregate_failures do
      setting = TestSetting.find_or_initialize_by(var: "host")

      expect(setting).not_to be_valid
      expect(setting.errors.size).to eq 1
      expect(setting.errors_as_sentence).to eq "Host can't be blank"
    end

    it "validates a value's format", :aggregate_failures do
      setting = TestSetting.find_or_initialize_by(var: "user_limits")

      expect(setting).not_to be_valid
      expect(setting.errors.size).to eq 2
      expect(setting.errors_as_sentence)
        .to eq "User limits can't be blank and User limits must be numbers"
    end

    it "validates a value's inclusion in a list of options", :aggregate_failures do
      setting = TestSetting.find_or_initialize_by(var: "mailer_provider")

      expect(setting).not_to be_valid
      expect(setting.errors.size).to eq 2
      expect(setting.errors_as_sentence)
        .to eq "Mailer provider can't be blank and Mailer provider is not included in the list"
    end

    it "raises validation errors on assignment" do
      expect { TestSetting.host = nil }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Host can't be blank")
    end
  end
end
