# frozen_string_literal: true

require 'capybara'

module Capybara
  module DSL
    def self.included(base)
      warn 'including Capybara::DSL in the global scope is not recommended!' if base == Object
      super
    end

    def self.extended(base)
      warn 'extending the main object with Capybara::DSL is not recommended!' if base == TOPLEVEL_BINDING.eval('self')
      super
    end

    ##
    #
    # Shortcut to working in a different session.
    #
    def using_session(name_or_session, &block)
      Capybara.using_session(name_or_session, &block)
    end

    # Shortcut to using a different wait time.
    #
    def using_wait_time(seconds, &block)
      page.using_wait_time(seconds, &block)
    end

    ##
    #
    # Shortcut to accessing the current session.
    #
    #     class MyClass
    #       include Capybara::DSL
    #
    #       def has_header?
    #         page.has_css?('h1')
    #       end
    #     end
    #
    # @return [Capybara::Session] The current session object
    #
    def page
      Capybara.current_session
    end

    Session::DSL_METHODS.each do |method|
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(...)
          page.method("#{method}").call(...)
        end
      METHOD
    end
  end

  extend(Capybara::DSL)
end
