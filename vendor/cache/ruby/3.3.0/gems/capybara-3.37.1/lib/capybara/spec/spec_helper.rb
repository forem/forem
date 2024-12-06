# frozen_string_literal: true

require 'rspec'
require 'rspec/expectations'
require 'capybara'
require 'capybara/rspec' # Required here instead of in rspec_spec to avoid RSpec deprecation warning
require 'capybara/spec/test_app'
require 'nokogiri'

Capybara.save_path = File.join(Dir.pwd, 'save_path_tmp')

module Capybara
  module SpecHelper
    class << self
      def configure(config)
        config.filter_run_excluding requires: method(:filter).to_proc
        config.before { Capybara::SpecHelper.reset! }
        config.after { Capybara::SpecHelper.reset! }
        config.shared_context_metadata_behavior = :apply_to_host_groups
      end

      def reset!
        Capybara.app = TestApp
        Capybara.app_host = nil
        Capybara.default_selector = :xpath
        Capybara.default_max_wait_time = 1
        Capybara.ignore_hidden_elements = true
        Capybara.exact = false
        Capybara.raise_server_errors = true
        Capybara.visible_text_only = false
        Capybara.match = :smart
        Capybara.enable_aria_label = false
        Capybara.enable_aria_role = false
        Capybara.default_set_options = {}
        Capybara.disable_animation = false
        Capybara.test_id = nil
        Capybara.predicates_wait = true
        Capybara.default_normalize_ws = false
        Capybara.use_html5_parsing = !ENV['HTML5_PARSING'].nil?
        Capybara.w3c_click_offset = false
        reset_threadsafe
      end

      def filter(requires, metadata)
        if requires && metadata[:capybara_skip]
          requires.any? do |require|
            metadata[:capybara_skip].include?(require)
          end
        else
          false
        end
      end

      def spec(name, *options, &block)
        @specs ||= []
        @specs << [name, options, block]
      end

      def run_specs(session, name, **options, &filter_block)
        specs = @specs
        RSpec.describe Capybara::Session, name, options do
          include Capybara::SpecHelper
          include Capybara::RSpecMatchers

          before do |example|
            @session = session
            instance_exec(example, &filter_block) if filter_block
          end

          after do
            session.reset_session!
          end

          before :each, psc: true do
            SpecHelper.reset_threadsafe(bool: true, session: session)
          end

          after psc: true do
            SpecHelper.reset_threadsafe(session: session)
          end

          before :each, :exact_false do
            Capybara.exact = false
          end

          specs.each do |spec_name, spec_options, block|
            describe spec_name, *spec_options do
              class_eval(&block)
            end
          end
        end
      end

      def reset_threadsafe(bool: false, session: nil)
        # Work around limit on when threadsafe can be changed
        Capybara::Session.class_variable_set(:@@instance_created, false) # rubocop:disable Style/ClassVars
        Capybara.threadsafe = bool
        session = session.current_session if session.respond_to?(:current_session)
        session&.instance_variable_set(:@config, nil)
      end
    end

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RbConfig::CONFIG['host_os'].match?(/rmswin|mingw/) ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end

    def quietly(&block)
      silence_stream($stdout) do
        silence_stream($stderr, &block)
      end
    end

    def extract_results(session)
      expect(session).to have_xpath("//pre[@id='results']")
      perms = [(::Sinatra::IndifferentHash if defined? ::Sinatra::IndifferentHash)].compact
      results = Capybara::HTML(session.body).xpath("//pre[@id='results']").first.inner_html.lstrip
      YAML.safe_load results, permitted_classes: perms
    end

    def be_an_invalid_element_error(session)
      satisfy { |error| session.driver.invalid_element_errors.any? { |e| error.is_a? e } }
    end

    def with_os_path_separators(path)
      Gem.win_platform? ? path.to_s.tr('/', '\\') : path.to_s
    end
  end
end

Dir["#{File.dirname(__FILE__)}/session/**/*.rb"].each { |file| require_relative file }
