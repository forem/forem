# rubocop:disable RSpec/DescribeClass
require "rails_helper"

describe "Framework Defaults 7.1 Upgrade Verification" do
  it "uses load_defaults 7.1 but keeps key_generator_hash_digest_class as SHA1" do
    # Verify load_defaults 7.1 properties are set, with cache format version updated to 7.1
    expect(Rails.application.config.active_support.hash_digest_class).to eq(OpenSSL::Digest::SHA256)
    expect(ActionView::Helpers::UrlHelper.button_to_generates_button_tag).to be(true)
    expect(ActiveSupport.cache_format_version).to eq(7.1)

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

  it "enables key Rails 7.1 defaults to ease the upgrade path" do
    config = Rails.application.config

    expect(config.action_dispatch.default_headers).not_to have_key("X-Download-Options")
    expect(config.action_controller.allow_deprecated_parameters_hash_equality).to be(false)
    expect(config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction).to be(false)
    expect(config.active_record.allow_deprecated_singular_associations_name).to be(false)
    expect(config.active_support.raise_on_invalid_cache_expiration_time).to be(true)
    expect(config.active_record.query_log_tags_format).to eq(:sqlcommenter)
    expect(config.active_support.message_serializer).to eq(:json_allow_marshal)
    expect(config.active_support.use_message_serializer_for_metadata).to be(true)
    expect(config.active_record.encryption.hash_digest_class).to eq(OpenSSL::Digest::SHA256)
    expect(config.active_record.encryption.support_sha1_for_non_deterministic_encryption).to be(false)
    expect(config.active_record.raise_on_assign_to_attr_readonly).to be(true)
    expect(config.active_record.belongs_to_required_validates_foreign_key).to be(true)
    expect(config.precompile_filter_parameters).to be(true)
    expect(config.active_record.before_committed_on_all_records).to be(true)
    expect(config.active_record.run_after_transaction_callbacks_in_order_defined).to be(true)
    expect(config.active_record.commit_transaction_on_non_local_return).to be(true)
    active_job_val = config.try(:active_job)&.use_big_decimal_serializer
    expect(active_job_val).to be(true)
    expect(config.active_record.marshalling_format_version).to eq(7.1)
    expect(config.active_record.default_column_serializer).to be_nil
    expect(config.active_record.generate_secure_token_on).to eq(:initialize)
    expect(ActionView::Base.sanitizer_vendor).to eq(Rails::HTML::Sanitizer.best_supported_vendor)
    expect(config.action_dispatch.debug_exception_log_level).to eq(:error)
    expect(config.dom_testing_default_html_version).to eq(:html5)
    expect(config.action_controller.raise_on_missing_callback_actions).to be(true)
  end

  it "does not have any controllers with missing callback actions" do
    # Eager load all classes
    Rails.application.eager_load!

    # Find all AbstractController::Base subclasses that respond to callback methods
    controllers = ObjectSpace.each_object(Class).select do |klass|
      klass < AbstractController::Base && klass.respond_to?(:_process_action_callbacks) && klass.name.present? && !klass.name.start_with?("HTML::")
    end

    missing_callbacks = []

    controllers.each do |klass|
      begin
        controller = klass.new
      rescue StandardError
        controller = nil
      end

      klass._process_action_callbacks.each do |callback|
        conditions = (callback.instance_variable_get(:@if) || []) + (callback.instance_variable_get(:@unless) || [])

        conditions.each do |cond|
          action_filter = nil
          if cond.is_a?(AbstractController::Callbacks::ActionFilter)
            action_filter = cond
          elsif cond.respond_to?(:target) && cond.target.is_a?(AbstractController::Callbacks::ActionFilter)
            action_filter = cond.target
          elsif cond.respond_to?(:instance_variable_get)
            block = cond.instance_variable_get(:@block)
            if block.is_a?(AbstractController::Callbacks::ActionFilter)
              action_filter = block
            end
          end

          next unless action_filter

          if controller
            begin
              original_val = controller.raise_on_missing_callback_actions
              controller.raise_on_missing_callback_actions = true
              action_filter.match?(controller)
            rescue AbstractController::ActionNotFound => e
              missing_callbacks << e.message.strip
            ensure
              controller.raise_on_missing_callback_actions = original_val
            end
          else
            actions = action_filter.instance_variable_get(:@actions) || []
            actions.each do |action|
              unless klass.action_methods.include?(action.to_s)
                missing_callbacks << "The #{action} action could not be found for #{callback.filter} callback on #{klass.name}."
              end
            end
          end
        end
      end
    end

    expect(missing_callbacks).to be_empty, -> {
      "Found controllers with missing callback actions:\n" + missing_callbacks.join("\n")
    }
  end

  describe "Framework Defaults 7.2 Upgrade Preparation" do
    it "has the new_framework_defaults_7_2.rb initializer file present" do
      expect(File.exist?(Rails.root.join("config/initializers/new_framework_defaults_7_2.rb"))).to be(true)
    end

    it "enables key Rails 7.2 defaults to ease the upgrade path" do
      config = Rails.application.config

      expect(config.active_record.validate_migration_timestamps).to be(true)
      expect(config.active_record.postgresql_adapter_decode_dates).to be(true)
      expect(config.active_job.enqueue_after_transaction_commit).to eq(:default)
      expect(config.active_support.to_time_preserves_timezone).to eq(:zone)
    end

    it "keeps remaining new Rails 7.2 configurations unset/nil (preserving Rails 7.1 defaults) during preparation" do
      config = Rails.application.config

      # active_storage and yjit are not loaded/supported in Rails 7.1, so they remain undefined
      expect(config.respond_to?(:active_storage)).to be(false)
      expect(config.respond_to?(:yjit)).to be(false)
    end
  end

  describe "Framework Defaults 8.0 Upgrade Preparation" do
    it "sets default Regexp timeout to protect against ReDoS" do
      if Regexp.respond_to?(:timeout)
        expected_timeout = ENV.fetch("REGEXP_TIMEOUT", "1.0")
        if expected_timeout.blank? || %w[nil none false].include?(expected_timeout.downcase)
          expect(Regexp.timeout).to be_nil
        else
          expect(Regexp.timeout).to eq(expected_timeout.to_f)
        end
      end
    end

    it "enables strict freshness to prioritize ETag over Last-Modified" do
      expect(Rails.application.config.action_dispatch.strict_freshness).to be(true)
    end

    describe "Regexp timeout parser logic" do
      after do
        # Restore the original timeout value
        if Regexp.respond_to?(:timeout=)
          original_timeout = ENV.fetch("REGEXP_TIMEOUT", "1.0")
          Regexp.timeout = if original_timeout.blank? || %w[nil none false].include?(original_timeout.downcase)
                             nil
                           else
                             original_timeout.to_f
                           end
        end
      end

      it "correctly parses and applies Regexp timeouts" do
        skip "Regexp.timeout not supported in this Ruby version" unless Regexp.respond_to?(:timeout=)

        # Test setting a custom float value
        stub_const("ENV", ENV.to_h.merge("REGEXP_TIMEOUT" => "2.5"))
        load Rails.root.join("config/initializers/regexp_timeout.rb")
        expect(Regexp.timeout).to eq(2.5)

        # Test disabling the timeout with 'nil'
        stub_const("ENV", ENV.to_h.merge("REGEXP_TIMEOUT" => "nil"))
        load Rails.root.join("config/initializers/regexp_timeout.rb")
        expect(Regexp.timeout).to be_nil

        # Test disabling the timeout with 'none'
        stub_const("ENV", ENV.to_h.merge("REGEXP_TIMEOUT" => "none"))
        load Rails.root.join("config/initializers/regexp_timeout.rb")
        expect(Regexp.timeout).to be_nil

        # Test disabling the timeout with 'false'
        stub_const("ENV", ENV.to_h.merge("REGEXP_TIMEOUT" => "false"))
        load Rails.root.join("config/initializers/regexp_timeout.rb")
        expect(Regexp.timeout).to be_nil
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
