# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # A {Capybara::Node::Base} represents either an element on a page through the subclass
    # {Capybara::Node::Element} or a document through {Capybara::Node::Document}.
    #
    # Both types of Node share the same methods, used for interacting with the
    # elements on the page. These methods are divided into three categories,
    # finders, actions and matchers. These are found in the modules
    # {Capybara::Node::Finders}, {Capybara::Node::Actions} and {Capybara::Node::Matchers}
    # respectively.
    #
    # A {Capybara::Session} exposes all methods from {Capybara::Node::Document} directly:
    #
    #     session = Capybara::Session.new(:rack_test, my_app)
    #     session.visit('/')
    #     session.fill_in('Foo', with: 'Bar')    # from Capybara::Node::Actions
    #     bar = session.find('#bar')                # from Capybara::Node::Finders
    #     bar.select('Baz', from: 'Quox')        # from Capybara::Node::Actions
    #     session.has_css?('#foobar')               # from Capybara::Node::Matchers
    #
    class Base
      attr_reader :session, :base, :query_scope

      include Capybara::Node::Finders
      include Capybara::Node::Actions
      include Capybara::Node::Matchers

      def initialize(session, base)
        @session = session
        @base = base
      end

      # overridden in subclasses, e.g. Capybara::Node::Element
      def reload
        self
      end

      ##
      #
      # This method is Capybara's primary defence against asynchronicity
      # problems. It works by attempting to run a given block of code until it
      # succeeds. The exact behaviour of this method depends on a number of
      # factors. Basically there are certain exceptions which, when raised
      # from the block, instead of bubbling up, are caught, and the block is
      # re-run.
      #
      # Certain drivers, such as RackTest, have no support for asynchronous
      # processes, these drivers run the block, and any error raised bubbles up
      # immediately. This allows faster turn around in the case where an
      # expectation fails.
      #
      # Only exceptions that are {Capybara::ElementNotFound} or any subclass
      # thereof cause the block to be rerun. Drivers may specify additional
      # exceptions which also cause reruns. This usually occurs when a node is
      # manipulated which no longer exists on the page. For example, the
      # Selenium driver specifies
      # `Selenium::WebDriver::Error::ObsoleteElementError`.
      #
      # As long as any of these exceptions are thrown, the block is re-run,
      # until a certain amount of time passes. The amount of time defaults to
      # {Capybara.default_max_wait_time} and can be overridden through the `seconds`
      # argument. This time is compared with the system time to see how much
      # time has passed. On rubies/platforms which don't support access to a monotonic process clock
      # if the return value of `Time.now` is stubbed out, Capybara will raise `Capybara::FrozenInTime`.
      #
      # @param  [Integer] seconds  (current sessions default_max_wait_time) Maximum number of seconds to retry this block
      # @param  [Array<Exception>] errors (driver.invalid_element_errors +
      #   [Capybara::ElementNotFound]) exception types that cause the block to be rerun
      # @return [Object]                  The result of the given block
      # @raise  [Capybara::FrozenInTime]  If the return value of `Time.now` appears stuck
      #
      def synchronize(seconds = nil, errors: nil)
        return yield if session.synchronized

        seconds = session_options.default_max_wait_time if [nil, true].include? seconds
        session.synchronized = true
        timer = Capybara::Helpers.timer(expire_in: seconds)
        begin
          yield
        rescue StandardError => e
          session.raise_server_error!
          raise e unless catch_error?(e, errors)

          if driver.wait?
            raise e if timer.expired?

            sleep(0.01)
            reload if session_options.automatic_reload
          else
            old_base = @base
            reload if session_options.automatic_reload
            raise e if old_base == @base
          end
          retry
        ensure
          session.synchronized = false
        end
      end

      # @api private
      def find_css(css, **options)
        if base.method(:find_css).arity == 1
          base.find_css(css)
        else
          base.find_css(css, **options)
        end
      end

      # @api private
      def find_xpath(xpath, **options)
        if base.method(:find_xpath).arity == 1
          base.find_xpath(xpath)
        else
          base.find_xpath(xpath, **options)
        end
      end

      # @api private
      def session_options
        session.config
      end

      def to_capybara_node
        self
      end

    protected

      def catch_error?(error, errors = nil)
        errors ||= (driver.invalid_element_errors + [Capybara::ElementNotFound])
        errors.any? { |type| error.is_a?(type) }
      end

      def driver
        session.driver
      end
    end
  end
end
