# rubocop:disable RSpec/DescribeClass
require "rails_helper"

describe "Framework Defaults 7.0 Upgrade Verification" do
  it "uses load_defaults 7.0 but keeps key_generator_hash_digest_class as SHA1" do
    # Verify load_defaults 7.0 properties are set, except cache format version which is override-compatible with 6.1
    expect(Rails.application.config.active_support.hash_digest_class).to eq(OpenSSL::Digest::SHA256)
    expect(ActionView::Helpers::UrlHelper.button_to_generates_button_tag).to be(true)
    expect(ActiveSupport.cache_format_version).to eq(6.1)

    # Verify key generator uses SHA1 for backward session/cookie compatibility
    expect(Rails.application.config.active_support.key_generator_hash_digest_class).to eq(OpenSSL::Digest::SHA1)
  end

  it "does not enable obsolete default_enforce_utf8" do
    expect(Rails.application.config.action_view.default_enforce_utf8).to be(false).or be_nil
  end

  it "does not enable obsolete read_encrypted_secrets" do
    config = Rails.application.config
    val = config.respond_to?(:read_encrypted_secrets) ? config.read_encrypted_secrets : nil
    expect(val).to be(false).or be_nil
  end
end

describe "Framework Defaults 7.1 Upgrade Preparation" do
  it "has the new_framework_defaults_7_1.rb initializer file" do
    expect(File.exist?(Rails.root.join("config/initializers/new_framework_defaults_7_1.rb"))).to be(true)
  end
end
# rubocop:enable RSpec/DescribeClass
