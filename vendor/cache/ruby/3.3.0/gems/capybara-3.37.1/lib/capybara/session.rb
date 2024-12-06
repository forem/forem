# frozen_string_literal: true

require 'capybara/session/matchers'
require 'addressable/uri'

module Capybara
  ##
  #
  # The {Session} class represents a single user's interaction with the system. The {Session} can use
  # any of the underlying drivers. A session can be initialized manually like this:
  #
  #     session = Capybara::Session.new(:culerity, MyRackApp)
  #
  # The application given as the second argument is optional. When running Capybara against an external
  # page, you might want to leave it out:
  #
  #     session = Capybara::Session.new(:culerity)
  #     session.visit('http://www.google.com')
  #
  # When {Capybara.configure threadsafe} is `true` the sessions options will be initially set to the
  # current values of the global options and a configuration block can be passed to the session initializer.
  # For available options see {Capybara::SessionConfig::OPTIONS}:
  #
  #     session = Capybara::Session.new(:driver, MyRackApp) do |config|
  #       config.app_host = "http://my_host.dev"
  #     end
  #
  # The {Session} provides a number of methods for controlling the navigation of the page, such as {#visit},
  # {#current_path}, and so on. It also delegates a number of methods to a {Capybara::Document}, representing
  # the current HTML document. This allows interaction:
  #
  #     session.fill_in('q', with: 'Capybara')
  #     session.click_button('Search')
  #     expect(session).to have_content('Capybara')
  #
  # When using `capybara/dsl`, the {Session} is initialized automatically for you.
  #
  class Session
    include Capybara::SessionMatchers

    NODE_METHODS = %i[
      all first attach_file text check choose scroll_to scroll_by
      click_link_or_button click_button click_link
      fill_in find find_all find_button find_by_id find_field find_link
      has_content? has_text? has_css? has_no_content? has_no_text?
      has_no_css? has_no_xpath? has_xpath? select uncheck
      has_link? has_no_link? has_button? has_no_button? has_field?
      has_no_field? has_checked_field? has_unchecked_field?
      has_no_table? has_table? unselect has_select? has_no_select?
      has_selector? has_no_selector? click_on has_no_checked_field?
      has_no_unchecked_field? query assert_selector assert_no_selector
      assert_all_of_selectors assert_none_of_selectors assert_any_of_selectors
      refute_selector assert_text assert_no_text
    ].freeze
    # @api private
    DOCUMENT_METHODS = %i[
      title assert_title assert_no_title has_title? has_no_title?
    ].freeze
    SESSION_METHODS = %i[
      body html source current_url current_host current_path
      execute_script evaluate_script visit refresh go_back go_forward send_keys
      within within_element within_fieldset within_table within_frame switch_to_frame
      current_window windows open_new_window switch_to_window within_window window_opened_by
      save_page save_and_open_page save_screenshot
      save_and_open_screenshot reset_session! response_headers
      status_code current_scope
      assert_current_path assert_no_current_path has_current_path? has_no_current_path?
    ].freeze + DOCUMENT_METHODS
    MODAL_METHODS = %i[
      accept_alert accept_confirm dismiss_confirm accept_prompt dismiss_prompt
    ].freeze
    DSL_METHODS = NODE_METHODS + SESSION_METHODS + MODAL_METHODS

    attr_reader :mode, :app, :server
    attr_accessor :synchronized

    def initialize(mode, app = nil)
      if app && !app.respond_to?(:call)
        raise TypeError, 'The second parameter to Session::new should be a rack app if passed.'
      end

      @@instance_created = true # rubocop:disable Style/ClassVars
      @mode = mode
      @app = app
      if block_given?
        raise 'A configuration block is only accepted when Capybara.threadsafe == true' unless Capybara.threadsafe

        yield config
      end
      @server = if config.run_server && @app && driver.needs_server?
        server_options = { port: config.server_port, host: config.server_host, reportable_errors: config.server_errors }
        server_options[:extra_middleware] = [Capybara::Server::AnimationDisabler] if config.disable_animation
        Capybara::Server.new(@app, **server_options).boot
      end
      @touched = false
    end

    def driver
      @driver ||= begin
        unless Capybara.drivers[mode]
          other_drivers = Capybara.drivers.names.map(&:inspect)
          raise Capybara::DriverNotFoundError, "no driver called #{mode.inspect} was found, available drivers: #{other_drivers.join(', ')}"
        end
        driver = Capybara.drivers[mode].call(app)
        driver.session = self if driver.respond_to?(:session=)
        driver
      end
    end

    ##
    #
    # Reset the session (i.e. remove cookies and navigate to blank page).
    #
    # This method does not:
    #
    # * accept modal dialogs if they are present (Selenium driver now does, others may not)
    # * clear browser cache/HTML 5 local storage/IndexedDB/Web SQL database/etc.
    # * modify state of the driver/underlying browser in any other way
    #
    # as doing so will result in performance downsides and it's not needed to do everything from the list above for most apps.
    #
    # If you want to do anything from the list above on a general basis you can:
    #
    # * write RSpec/Cucumber/etc. after hook
    # * monkeypatch this method
    # * use Ruby's `prepend` method
    #
    def reset!
      if @touched
        driver.reset!
        @touched = false
      end
      @server&.wait_for_pending_requests
      raise_server_error!
    end
    alias_method :cleanup!, :reset!
    alias_method :reset_session!, :reset!

    ##
    #
    # Disconnect from the current driver. A new driver will be instantiated on the next interaction.
    #
    def quit
      @driver.quit if @driver.respond_to? :quit
      @document = @driver = nil
      @touched = false
      @server&.reset_error!
    end

    ##
    #
    # Raise errors encountered in the server.
    #
    def raise_server_error!
      return unless @server&.error

      # Force an explanation for the error being raised as the exception cause
      begin
        if config.raise_server_errors
          raise CapybaraError, 'Your application server raised an error - It has been raised in your test code because Capybara.raise_server_errors == true'
        end
      rescue CapybaraError
        # needed to get the cause set correctly in JRuby -- otherwise we could just do raise @server.error
        raise @server.error, @server.error.message, @server.error.backtrace
      ensure
        @server.reset_error!
      end
    end

    ##
    #
    # Returns a hash of response headers. Not supported by all drivers (e.g. Selenium).
    #
    # @return [Hash<String, String>] A hash of response headers.
    #
    def response_headers
      driver.response_headers
    end

    ##
    #
    # Returns the current HTTP status code as an integer. Not supported by all drivers (e.g. Selenium).
    #
    # @return [Integer] Current HTTP status code
    #
    def status_code
      driver.status_code
    end

    ##
    #
    # @return [String] A snapshot of the DOM of the current document, as it looks right now (potentially modified by JavaScript).
    #
    def html
      driver.html || ''
    end
    alias_method :body, :html
    alias_method :source, :html

    ##
    #
    # @return [String] Path of the current page, without any domain information
    #
    def current_path
      # Addressable parsing is more lenient than URI
      uri = ::Addressable::URI.parse(current_url)

      # Addressable doesn't support opaque URIs - we want nil here
      return nil if uri&.scheme == 'about'

      path = uri&.path
      path unless path&.empty?
    end

    ##
    #
    # @return [String] Host of the current page
    #
    def current_host
      uri = URI.parse(current_url)
      "#{uri.scheme}://#{uri.host}" if uri.host
    end

    ##
    #
    # @return [String] Fully qualified URL of the current page
    #
    def current_url
      driver.current_url
    end

    ##
    #
    # Navigate to the given URL. The URL can either be a relative URL or an absolute URL
    # The behaviour of either depends on the driver.
    #
    #     session.visit('/foo')
    #     session.visit('http://google.com')
    #
    # For drivers which can run against an external application, such as the selenium driver
    # giving an absolute URL will navigate to that page. This allows testing applications
    # running on remote servers. For these drivers, setting {Capybara.configure app_host} will make the
    # remote server the default. For example:
    #
    #     Capybara.app_host = 'http://google.com'
    #     session.visit('/') # visits the google homepage
    #
    # If {Capybara.configure always_include_port} is set to `true` and this session is running against
    # a rack application, then the port that the rack application is running on will automatically
    # be inserted into the URL. Supposing the app is running on port `4567`, doing something like:
    #
    #     visit("http://google.com/test")
    #
    # Will actually navigate to `http://google.com:4567/test`.
    #
    # @param [#to_s] visit_uri     The URL to navigate to. The parameter will be cast to a String.
    #
    def visit(visit_uri)
      raise_server_error!
      @touched = true

      visit_uri = ::Addressable::URI.parse(visit_uri.to_s)
      base_uri = ::Addressable::URI.parse(config.app_host || server_url)

      if base_uri && [nil, 'http', 'https'].include?(visit_uri.scheme)
        if visit_uri.relative?
          visit_uri_parts = visit_uri.to_hash.compact

          # Useful to people deploying to a subdirectory
          # and/or single page apps where only the url fragment changes
          visit_uri_parts[:path] = base_uri.path + visit_uri.path

          visit_uri = base_uri.merge(visit_uri_parts)
        end
        adjust_server_port(visit_uri)
      end

      driver.visit(visit_uri.to_s)
    end

    ##
    #
    # Refresh the page.
    #
    def refresh
      raise_server_error!
      driver.refresh
    end

    ##
    #
    # Move back a single entry in the browser's history.
    #
    def go_back
      driver.go_back
    end

    ##
    #
    # Move forward a single entry in the browser's history.
    #
    def go_forward
      driver.go_forward
    end

    ##
    # @!method send_keys
    #   @see Capybara::Node::Element#send_keys
    #
    def send_keys(*args, **kw_args)
      driver.send_keys(*args, **kw_args)
    end

    ##
    #
    # Returns the element with focus.
    #
    # Not supported by Rack Test
    #
    def active_element
      Capybara::Queries::ActiveElementQuery.new.resolve_for(self)[0].tap(&:allow_reload!)
    end

    ##
    #
    # Executes the given block within the context of a node. {#within} takes the
    # same options as {Capybara::Node::Finders#find #find}, as well as a block. For the duration of the
    # block, any command to Capybara will be handled as though it were scoped
    # to the given element.
    #
    #     within(:xpath, './/div[@id="delivery-address"]') do
    #       fill_in('Street', with: '12 Main Street')
    #     end
    #
    # Just as with `#find`, if multiple elements match the selector given to
    # {#within}, an error will be raised, and just as with `#find`, this
    # behaviour can be controlled through the `:match` and `:exact` options.
    #
    # It is possible to omit the first parameter, in that case, the selector is
    # assumed to be of the type set in {Capybara.configure default_selector}.
    #
    #     within('div#delivery-address') do
    #       fill_in('Street', with: '12 Main Street')
    #     end
    #
    # Note that a lot of uses of {#within} can be replaced more succinctly with
    # chaining:
    #
    #     find('div#delivery-address').fill_in('Street', with: '12 Main Street')
    #
    # @overload within(*find_args)
    #   @param (see Capybara::Node::Finders#all)
    #
    # @overload within(a_node)
    #   @param [Capybara::Node::Base] a_node   The node in whose scope the block should be evaluated
    #
    # @raise  [Capybara::ElementNotFound]      If the scope can't be found before time expires
    #
    def within(*args, **kw_args)
      new_scope = args.first.respond_to?(:to_capybara_node) ? args.first.to_capybara_node : find(*args, **kw_args)
      begin
        scopes.push(new_scope)
        yield if block_given?
      ensure
        scopes.pop
      end
    end
    alias_method :within_element, :within

    ##
    #
    # Execute the given block within the a specific fieldset given the id or legend of that fieldset.
    #
    # @param [String] locator    Id or legend of the fieldset
    #
    def within_fieldset(locator, &block)
      within(:fieldset, locator, &block)
    end

    ##
    #
    # Execute the given block within the a specific table given the id or caption of that table.
    #
    # @param [String] locator    Id or caption of the table
    #
    def within_table(locator, &block)
      within(:table, locator, &block)
    end

    ##
    #
    # Switch to the given frame.
    #
    # If you use this method you are responsible for making sure you switch back to the parent frame when done in the frame changed to.
    # {#within_frame} is preferred over this method and should be used when possible.
    # May not be supported by all drivers.
    #
    # @overload switch_to_frame(element)
    #   @param [Capybara::Node::Element] element    iframe/frame element to switch to
    # @overload switch_to_frame(location)
    #   @param [Symbol] location relative location of the frame to switch to
    #                            * :parent - the parent frame
    #                            * :top - the top level document
    #
    def switch_to_frame(frame)
      case frame
      when Capybara::Node::Element
        driver.switch_to_frame(frame)
        scopes.push(:frame)
      when :parent
        if scopes.last != :frame
          raise Capybara::ScopeError, "`switch_to_frame(:parent)` cannot be called from inside a descendant frame's "\
                                      '`within` block.'
        end
        scopes.pop
        driver.switch_to_frame(:parent)
      when :top
        idx = scopes.index(:frame)
        top_level_scopes = [:frame, nil]
        if idx
          if scopes.slice(idx..).any? { |scope| !top_level_scopes.include?(scope) }
            raise Capybara::ScopeError, "`switch_to_frame(:top)` cannot be called from inside a descendant frame's "\
                                        '`within` block.'
          end
          scopes.slice!(idx..)
          driver.switch_to_frame(:top)
        end
      else
        raise ArgumentError, 'You must provide a frame element, :parent, or :top when calling switch_to_frame'
      end
    end

    ##
    #
    # Execute the given block within the given iframe using given frame, frame name/id or index.
    # May not be supported by all drivers.
    #
    # @overload within_frame(element)
    #   @param [Capybara::Node::Element]  frame element
    # @overload within_frame([kind = :frame], locator, **options)
    #   @param [Symbol] kind      Optional selector type (:frame, :css, :xpath, etc.) - Defaults to :frame
    #   @param [String] locator   The locator for the given selector kind.  For :frame this is the name/id of a frame/iframe element
    # @overload within_frame(index)
    #   @param [Integer] index         index of a frame (0 based)
    def within_frame(*args, **kw_args)
      switch_to_frame(_find_frame(*args, **kw_args))
      begin
        yield if block_given?
      ensure
        switch_to_frame(:parent)
      end
    end

    ##
    # @return [Capybara::Window]   current window
    #
    def current_window
      Window.new(self, driver.current_window_handle)
    end

    ##
    # Get all opened windows.
    # The order of windows in returned array is not defined.
    # The driver may sort windows by their creation time but it's not required.
    #
    # @return [Array<Capybara::Window>]   an array of all windows
    #
    def windows
      driver.window_handles.map do |handle|
        Window.new(self, handle)
      end
    end

    ##
    # Open a new window.
    # The current window doesn't change as the result of this call.
    # It should be switched to explicitly.
    #
    # @return [Capybara::Window]   window that has been opened
    #
    def open_new_window(kind = :tab)
      window_opened_by do
        if driver.method(:open_new_window).arity.zero?
          driver.open_new_window
        else
          driver.open_new_window(kind)
        end
      end
    end

    ##
    # Switch to the given window.
    #
    # @overload switch_to_window(&block)
    #   Switches to the first window for which given block returns a value other than false or nil.
    #   If window that matches block can't be found, the window will be switched back and {Capybara::WindowError} will be raised.
    #   @example
    #     window = switch_to_window { title == 'Page title' }
    #   @raise [Capybara::WindowError]     if no window matches given block
    # @overload switch_to_window(window)
    #   @param window [Capybara::Window]   window that should be switched to
    #   @raise [Capybara::Driver::Base#no_such_window_error] if nonexistent (e.g. closed) window was passed
    #
    # @return [Capybara::Window]         window that has been switched to
    # @raise [Capybara::ScopeError]        if this method is invoked inside {#within} or
    #   {#within_frame} methods
    # @raise [ArgumentError]               if both or neither arguments were provided
    #
    def switch_to_window(window = nil, **options, &window_locator)
      raise ArgumentError, '`switch_to_window` can take either a block or a window, not both' if window && window_locator
      raise ArgumentError, '`switch_to_window`: either window or block should be provided' if !window && !window_locator

      unless scopes.last.nil?
        raise Capybara::ScopeError, '`switch_to_window` is not supposed to be invoked from '\
                                    '`within` or `within_frame` blocks.'
      end

      _switch_to_window(window, **options, &window_locator)
    end

    ##
    # This method does the following:
    #
    # 1. Switches to the given window (it can be located by window instance/lambda/string).
    # 2. Executes the given block (within window located at previous step).
    # 3. Switches back (this step will be invoked even if an exception occurs at the second step).
    #
    # @overload within_window(window) { do_something }
    #   @param window [Capybara::Window]       instance of {Capybara::Window} class
    #     that will be switched to
    #   @raise [driver#no_such_window_error] if nonexistent (e.g. closed) window was passed
    # @overload within_window(proc_or_lambda) { do_something }
    #   @param lambda [Proc]                  First window for which lambda
    #     returns a value other than false or nil will be switched to.
    #   @example
    #     within_window(->{ page.title == 'Page title' }) { click_button 'Submit' }
    #   @raise [Capybara::WindowError]         if no window matching lambda was found
    #
    # @raise [Capybara::ScopeError]        if this method is invoked inside {#within_frame} method
    # @return                              value returned by the block
    #
    def within_window(window_or_proc)
      original = current_window
      scopes << nil
      begin
        case window_or_proc
        when Capybara::Window
          _switch_to_window(window_or_proc) unless original == window_or_proc
        when Proc
          _switch_to_window { window_or_proc.call }
        else
          raise ArgumentError, '`#within_window` requires a `Capybara::Window` instance or a lambda'
        end

        begin
          yield if block_given?
        ensure
          _switch_to_window(original) unless original == window_or_proc
        end
      ensure
        scopes.pop
      end
    end

    ##
    # Get the window that has been opened by the passed block.
    # It will wait for it to be opened (in the same way as other Capybara methods wait).
    # It's better to use this method than `windows.last`
    # {https://dvcs.w3.org/hg/webdriver/raw-file/default/webdriver-spec.html#h_note_10 as order of windows isn't defined in some drivers}.
    #
    # @overload window_opened_by(**options, &block)
    #   @param options [Hash]
    #   @option options [Numeric] :wait  maximum wait time. Defaults to {Capybara.configure default_max_wait_time}
    #   @return [Capybara::Window]       the window that has been opened within a block
    #   @raise [Capybara::WindowError]   if block passed to window hasn't opened window
    #     or opened more than one window
    #
    def window_opened_by(**options)
      old_handles = driver.window_handles
      yield

      synchronize_windows(options) do
        opened_handles = (driver.window_handles - old_handles)
        if opened_handles.size != 1
          raise Capybara::WindowError, 'block passed to #window_opened_by '\
                                       "opened #{opened_handles.size} windows instead of 1"
        end
        Window.new(self, opened_handles.first)
      end
    end

    ##
    #
    # Execute the given script, not returning a result. This is useful for scripts that return
    # complex objects, such as jQuery statements. {#execute_script} should be used over
    # {#evaluate_script} whenever possible.
    #
    # @param [String] script   A string of JavaScript to execute
    # @param args  Optional arguments that will be passed to the script. Driver support for this is optional and types of objects supported may differ between drivers
    #
    def execute_script(script, *args)
      @touched = true
      driver.execute_script(script, *driver_args(args))
    end

    ##
    #
    # Evaluate the given JavaScript and return the result. Be careful when using this with
    # scripts that return complex objects, such as jQuery statements. {#execute_script} might
    # be a better alternative.
    #
    # @param  [String] script   A string of JavaScript to evaluate
    # @param           args     Optional arguments that will be passed to the script
    # @return [Object]          The result of the evaluated JavaScript (may be driver specific)
    #
    def evaluate_script(script, *args)
      @touched = true
      result = driver.evaluate_script(script.strip, *driver_args(args))
      element_script_result(result)
    end

    ##
    #
    # Evaluate the given JavaScript and obtain the result from a callback function which will be passed as the last argument to the script.
    #
    # @param  [String] script   A string of JavaScript to evaluate
    # @param           args     Optional arguments that will be passed to the script
    # @return [Object]          The result of the evaluated JavaScript (may be driver specific)
    #
    def evaluate_async_script(script, *args)
      @touched = true
      result = driver.evaluate_async_script(script, *driver_args(args))
      element_script_result(result)
    end

    ##
    #
    # Execute the block, accepting a alert.
    #
    # @!macro modal_params
    #   Expects a block whose actions will trigger the display modal to appear.
    #   @example
    #     $0 do
    #       click_link('link that triggers appearance of system modal')
    #     end
    #   @overload $0(text, **options, &blk)
    #     @param text [String, Regexp]  Text or regex to match against the text in the modal. If not provided any modal is matched.
    #     @option options [Numeric] :wait  Maximum time to wait for the modal to appear after executing the block. Defaults to {Capybara.configure default_max_wait_time}.
    #     @yield Block whose actions will trigger the system modal
    #   @overload $0(**options, &blk)
    #     @option options [Numeric] :wait  Maximum time to wait for the modal to appear after executing the block. Defaults to {Capybara.configure default_max_wait_time}.
    #     @yield Block whose actions will trigger the system modal
    #   @return [String]  the message shown in the modal
    #   @raise [Capybara::ModalNotFound]  if modal dialog hasn't been found
    #
    def accept_alert(text = nil, **options, &blk)
      accept_modal(:alert, text, options, &blk)
    end

    ##
    #
    # Execute the block, accepting a confirm.
    #
    # @macro modal_params
    #
    def accept_confirm(text = nil, **options, &blk)
      accept_modal(:confirm, text, options, &blk)
    end

    ##
    #
    # Execute the block, dismissing a confirm.
    #
    # @macro modal_params
    #
    def dismiss_confirm(text = nil, **options, &blk)
      dismiss_modal(:confirm, text, options, &blk)
    end

    ##
    #
    # Execute the block, accepting a prompt, optionally responding to the prompt.
    #
    # @macro modal_params
    # @option options [String] :with   Response to provide to the prompt
    #
    def accept_prompt(text = nil, **options, &blk)
      accept_modal(:prompt, text, options, &blk)
    end

    ##
    #
    # Execute the block, dismissing a prompt.
    #
    # @macro modal_params
    #
    def dismiss_prompt(text = nil, **options, &blk)
      dismiss_modal(:prompt, text, options, &blk)
    end

    ##
    #
    # Save a snapshot of the page. If {Capybara.configure asset_host} is set it will inject `base` tag
    # pointing to {Capybara.configure asset_host}.
    #
    # If invoked without arguments it will save file to {Capybara.configure save_path}
    # and file will be given randomly generated filename. If invoked with a relative path
    # the path will be relative to {Capybara.configure save_path}.
    #
    # @param [String] path  the path to where it should be saved
    # @return [String]      the path to which the file was saved
    #
    def save_page(path = nil)
      prepare_path(path, 'html').tap do |p_path|
        File.write(p_path, Capybara::Helpers.inject_asset_host(body, host: config.asset_host), mode: 'wb')
      end
    end

    ##
    #
    # Save a snapshot of the page and open it in a browser for inspection.
    #
    # If invoked without arguments it will save file to {Capybara.configure save_path}
    # and file will be given randomly generated filename. If invoked with a relative path
    # the path will be relative to {Capybara.configure save_path}.
    #
    # @param [String] path  the path to where it should be saved
    #
    def save_and_open_page(path = nil)
      save_page(path).tap { |s_path| open_file(s_path) }
    end

    ##
    #
    # Save a screenshot of page.
    #
    # If invoked without arguments it will save file to {Capybara.configure save_path}
    # and file will be given randomly generated filename. If invoked with a relative path
    # the path will be relative to {Capybara.configure save_path}.
    #
    # @param [String] path    the path to where it should be saved
    # @param [Hash] options   a customizable set of options
    # @return [String]        the path to which the file was saved
    def save_screenshot(path = nil, **options)
      prepare_path(path, 'png').tap { |p_path| driver.save_screenshot(p_path, **options) }
    end

    ##
    #
    # Save a screenshot of the page and open it for inspection.
    #
    # If invoked without arguments it will save file to {Capybara.configure save_path}
    # and file will be given randomly generated filename. If invoked with a relative path
    # the path will be relative to {Capybara.configure save_path}.
    #
    # @param [String] path    the path to where it should be saved
    # @param [Hash] options   a customizable set of options
    #
    def save_and_open_screenshot(path = nil, **options)
      save_screenshot(path, **options).tap { |s_path| open_file(s_path) }
    end

    def document
      @document ||= Capybara::Node::Document.new(self, driver)
    end

    NODE_METHODS.each do |method|
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(...)
          @touched = true
          current_scope.#{method}(...)
        end
      METHOD
    end

    DOCUMENT_METHODS.each do |method|
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(...)
          document.#{method}(...)
        end
      METHOD
    end

    def inspect
      %(#<Capybara::Session>)
    end

    def current_scope
      scope = scopes.last
      [nil, :frame].include?(scope) ? document : scope
    end

    ##
    #
    # Yield a block using a specific maximum wait time.
    #
    def using_wait_time(seconds, &block)
      if Capybara.threadsafe
        begin
          previous_wait_time = config.default_max_wait_time
          config.default_max_wait_time = seconds
          yield
        ensure
          config.default_max_wait_time = previous_wait_time
        end
      else
        Capybara.using_wait_time(seconds, &block)
      end
    end

    ##
    #
    # Accepts a block to set the configuration options if {Capybara.configure threadsafe} is `true`. Note that some options only have an effect
    # if set at initialization time, so look at the configuration block that can be passed to the initializer too.
    #
    def configure
      raise 'Session configuration is only supported when Capybara.threadsafe == true' unless Capybara.threadsafe

      yield config
    end

    def self.instance_created?
      @@instance_created
    end

    def config
      @config ||= if Capybara.threadsafe
        Capybara.session_options.dup
      else
        Capybara::ReadOnlySessionConfig.new(Capybara.session_options)
      end
    end

    def server_url
      @server&.base_url
    end

  private

    @@instance_created = false # rubocop:disable Style/ClassVars

    def driver_args(args)
      args.map { |arg| arg.is_a?(Capybara::Node::Element) ? arg.base : arg }
    end

    def accept_modal(type, text_or_options, options, &blk)
      driver.accept_modal(type, **modal_options(text_or_options, **options), &blk)
    end

    def dismiss_modal(type, text_or_options, options, &blk)
      driver.dismiss_modal(type, **modal_options(text_or_options, **options), &blk)
    end

    def modal_options(text = nil, **options)
      options[:text] ||= text unless text.nil?
      options[:wait] ||= config.default_max_wait_time
      options
    end

    def open_file(path)
      require 'launchy'
      Launchy.open(path)
    rescue LoadError
      warn "File saved to #{path}.\nPlease install the launchy gem to open the file automatically."
    end

    def prepare_path(path, extension)
      File.expand_path(path || default_fn(extension), config.save_path).tap do |p_path|
        FileUtils.mkdir_p(File.dirname(p_path))
      end
    end

    def default_fn(extension)
      timestamp = Time.new.strftime('%Y%m%d%H%M%S')
      "capybara-#{timestamp}#{rand(10**10)}.#{extension}"
    end

    def scopes
      @scopes ||= [nil]
    end

    def element_script_result(arg)
      case arg
      when Array
        arg.map { |subarg| element_script_result(subarg) }
      when Hash
        arg.transform_values! { |value| element_script_result(value) }
      when Capybara::Driver::Node
        Capybara::Node::Element.new(self, arg, nil, nil)
      else
        arg
      end
    end

    def adjust_server_port(uri)
      uri.port ||= @server.port if @server && config.always_include_port
    end

    def _find_frame(*args, **kw_args)
      case args[0]
      when Capybara::Node::Element
        args[0]
      when String, nil
        find(:frame, *args, **kw_args)
      when Symbol
        find(*args, **kw_args)
      when Integer
        idx = args[0]
        all(:frame, minimum: idx + 1)[idx]
      else
        raise TypeError
      end
    end

    def _switch_to_window(window = nil, **options, &window_locator)
      raise Capybara::ScopeError, 'Window cannot be switched inside a `within_frame` block' if scopes.include?(:frame)
      raise Capybara::ScopeError, 'Window cannot be switched inside a `within` block' unless scopes.last.nil?

      if window
        driver.switch_to_window(window.handle)
        window
      else
        synchronize_windows(options) do
          original_window_handle = driver.current_window_handle
          begin
            _switch_to_window_by_locator(&window_locator)
          rescue StandardError
            driver.switch_to_window(original_window_handle)
            raise
          end
        end
      end
    end

    def _switch_to_window_by_locator
      driver.window_handles.each do |handle|
        driver.switch_to_window handle
        return Window.new(self, handle) if yield
      end
      raise Capybara::WindowError, 'Could not find a window matching block/lambda'
    end

    def synchronize_windows(options, &block)
      wait_time = Capybara::Queries::BaseQuery.wait(options, config.default_max_wait_time)
      document.synchronize(wait_time, errors: [Capybara::WindowError], &block)
    end
  end
end
