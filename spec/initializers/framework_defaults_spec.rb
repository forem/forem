# frozen_string_literal: true

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
end
