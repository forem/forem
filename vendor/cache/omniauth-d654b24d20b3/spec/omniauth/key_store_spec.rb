require 'helper'

RSpec.describe OmniAuth::KeyStore do
  let(:logger) { double('Logger') }

  around(:each) do |example|
    patched = monkey_patch_logger
    example.run
    remove_logger(patched)
  end

  context 'on Hashie < 3.5.0' do
    let(:version) { '3.4.0' }

    it 'does not log anything to the console' do
      stub_const('Hashie::VERSION', version)
      OmniAuth::KeyStore.override_logging
      expect(logger).not_to receive(:info)
      OmniAuth::KeyStore.new(:id => 1234)
    end
  end

  context 'on Hashie 3.5.0 and 3.5.1' do
    let(:version) { '3.5.0' }

    it 'does not log anything to the console' do
      stub_const('Hashie::VERSION', version)
      OmniAuth::KeyStore.override_logging
      expect(logger).not_to receive(:info)
      OmniAuth::KeyStore.new(:id => 1234)
    end
  end

  context 'on Hashie 3.5.2+' do
    let(:version) { '3.5.2' }

    around(:each) do |example|
      patching = monkey_patch_unreleased_interface
      example.run
      remove_monkey_patch(patching)
    end

    it 'does not log anything to the console' do
      stub_const('Hashie::VERSION', version)
      OmniAuth::KeyStore.override_logging
      expect(logger).not_to receive(:info)
      OmniAuth::KeyStore.new(:id => 1234)
    end
  end

  def monkey_patch_unreleased_interface
    return false if OmniAuth::KeyStore.class.respond_to?(:disable_warnings, true)

    OmniAuth::KeyStore.define_singleton_method(:disable_warnings) {}
    OmniAuth::KeyStore.define_singleton_method(:log_built_in_message) { |*| }

    true
  end

  def monkey_patch_logger
    return unless Hashie.respond_to?(:logger)

    original_logger = Hashie.logger
    Hashie.logger = logger
    original_logger
  end

  def remove_logger(logger)
    return unless logger

    Hashie.logger = logger
  end

  def remove_monkey_patch(perform)
    return unless perform

    OmniAuth::KeyStore.singleton_class.__send__(:remove_method, :disable_warnings)
  end
end
