# rubocop:disable RSpec/DescribeClass
require "rails_helper"

describe "Framework Defaults 7.0 Upgrade Verification" do
  it "uses load_defaults 7.0 but keeps key_generator_hash_digest_class as SHA1" do
    # Verify load_defaults 7.0 properties are set, except cache format version which is override-compatible with 7.0
    expect(Rails.application.config.active_support.hash_digest_class).to eq(OpenSSL::Digest::SHA256)
    expect(ActionView::Helpers::UrlHelper.button_to_generates_button_tag).to be(true)
    expect(ActiveSupport.cache_format_version).to eq(7.0)

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

  it "enables key Rails 7.1 defaults to ease the upgrade path" do
    config = Rails.application.config

    expect(config.action_dispatch.default_headers).not_to have_key("X-Download-Options")
    expect(config.action_controller.allow_deprecated_parameters_hash_equality).to be(false)
    expect(config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction).to be_nil.or be(true) # reverted to 7.0 default
    expect(config.active_record.allow_deprecated_singular_associations_name).to be(false)
    expect(config.active_support.raise_on_invalid_cache_expiration_time).to be(true)
    expect(config.active_record.query_log_tags_format).to eq(:sqlcommenter)
    expect(config.active_support.message_serializer).to be_nil.or eq(:marshal) # reverted to 7.0 default
    expect(config.active_support.use_message_serializer_for_metadata).to be_nil.or be(false) # reverted to 7.0 default
    expect(config.active_record.raise_on_assign_to_attr_readonly).to be(true)
    expect(config.active_record.belongs_to_required_validates_foreign_key).to be(true) # reverted to 7.0 default
    expect(config.precompile_filter_parameters).to be(true)
    expect(config.active_record.before_committed_on_all_records).to be_nil.or be(false) # reverted to 7.0 default
    expect(config.active_record.run_after_transaction_callbacks_in_order_defined).to be_nil.or be(false) # reverted to 7.0 default
    expect(config.active_record.commit_transaction_on_non_local_return).to be_nil.or be(false) # reverted to 7.0 default
    expect(config.active_record.generate_secure_token_on).to eq(:initialize)
    expect(ActionView::Base.sanitizer_vendor).to eq(Rails::HTML::Sanitizer.best_supported_vendor)
    expect(config.action_dispatch.debug_exception_log_level).to eq(:error)
    expect(config.dom_testing_default_html_version).to eq(:html5)
    expect(config.action_controller.raise_on_missing_callback_actions).to be_nil.or be(false) # reverted to 7.0 default
  end
end
# rubocop:enable RSpec/DescribeClass
