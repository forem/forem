# frozen_string_literal: true

module Capybara
  module RSpecMatcherProxies
    def all(*args, **kwargs, &block)
      if defined?(::RSpec::Matchers::BuiltIn::All) && args.first.respond_to?(:matches?)
        ::RSpec::Matchers::BuiltIn::All.new(*args)
      else
        find_all(*args, **kwargs, &block)
      end
    end

    def within(*args, **kwargs, &block)
      if block
        within_element(*args, **kwargs, &block)
      else
        be_within(*args)
      end
    end
  end
end

if RUBY_ENGINE == 'jruby'
  # :nocov:
  module Capybara::DSL
    class << self
      remove_method :included

      def included(base)
        warn 'including Capybara::DSL in the global scope is not recommended!' if base == Object
        if defined?(::RSpec::Matchers) && base.include?(::RSpec::Matchers)
          base.send(:include, ::Capybara::RSpecMatcherProxies)
        end
        super
      end
    end
  end

  if defined?(::RSpec::Matchers)
    module ::RSpec::Matchers
      def self.included(base)
        base.send(:include, ::Capybara::RSpecMatcherProxies) if base.include?(::Capybara::DSL)
        super
      end
    end
  end
  # :nocov:
else
  module Capybara::DSLRSpecProxyInstaller
    module ClassMethods
      def included(base)
        base.include(::Capybara::RSpecMatcherProxies) if defined?(::RSpec::Matchers) && base.include?(::RSpec::Matchers)
        super
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end

  module Capybara::RSpecMatcherProxyInstaller
    module ClassMethods
      def included(base)
        base.include(::Capybara::RSpecMatcherProxies) if base.include?(::Capybara::DSL)
        super
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end

  Capybara::DSL.prepend ::Capybara::DSLRSpecProxyInstaller

  ::RSpec::Matchers.prepend ::Capybara::RSpecMatcherProxyInstaller if defined?(::RSpec::Matchers)
end
