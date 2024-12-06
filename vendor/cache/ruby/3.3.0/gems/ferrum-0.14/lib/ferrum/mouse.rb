# frozen_string_literal: true

module Ferrum
  class Mouse
    CLICK_WAIT = ENV.fetch("FERRUM_CLICK_WAIT", 0.1).to_f
    VALID_BUTTONS = %w[none left middle right back forward].freeze

    def initialize(page)
      @page = page
      @x = @y = 0
    end

    #
    # Scroll page to a given x, y coordinates.
    #
    # @param [Integer] top
    #  The pixel along the horizontal axis of the document that you want
    #  displayed in the upper left.
    #
    # @param [Integer] left
    #   The pixel along the vertical axis of the document that you want
    #   displayed in the upper left.
    #
    # @example
    #   browser.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
    #   browser.mouse.scroll_to(0, 400)
    #
    def scroll_to(top, left)
      tap { @page.execute("window.scrollTo(#{top}, #{left})") }
    end

    #
    # Click given coordinates, fires mouse move, down and up events.
    #
    # @param [Integer] x
    #
    # @param [Integer] y
    #
    # @param [Float] delay
    #   Delay between mouse down and mouse up events.
    #
    # @param [Float] wait
    #
    # @param [Hash{Symbol => Object}] options
    #   Additional keyword arguments.
    #
    # @option options [:left, :right] :button (:left)
    #   The mouse button to click.
    #
    # @option options [Integer] :count (1)
    #
    # @option options [Integer] :modifiers
    #   Bitfield for key modifiers. See`keyboard.modifiers`.
    #
    # @return [self]
    #
    def click(x:, y:, delay: 0, wait: CLICK_WAIT, **options)
      move(x: x, y: y)
      down(**options)
      sleep(delay)
      # Potential wait because if some network event is triggered then we have
      # to wait until it's over and frame is loaded or failed to load.
      up(wait: wait, **options)
      self
    end

    #
    # Mouse down for given coordinates.
    #
    # @param [Hash{Symbol => Object}] options
    #   Additional keyword arguments.
    #
    # @option options [:left, :right] :button (:left)
    #   The mouse button to click.
    #
    # @option options [Integer] :count (1)
    #
    # @option options [Integer] :modifiers
    #   Bitfield for key modifiers. See`keyboard.modifiers`.
    #
    # @return [self]
    #
    def down(**options)
      tap { mouse_event(type: "mousePressed", **options) }
    end

    #
    # Mouse up for given coordinates.
    #
    # @param [Hash{Symbol => Object}] options
    #   Additional keyword arguments.
    #
    # @option options [:left, :right] :button (:left)
    #   The mouse button to click.
    #
    # @option options [Integer] :count (1)
    #
    # @option options [Integer] :modifiers
    #   Bitfield for key modifiers. See`keyboard.modifiers`.
    #
    # @return [self]
    #
    def up(**options)
      tap { mouse_event(type: "mouseReleased", **options) }
    end

    #
    # Mouse move to given x and y.
    #
    # @param [Integer] x
    #
    # @param [Integer] y
    #
    # @param [Integer] steps
    #   Sends intermediate mousemove events.
    #
    # @return [self]
    #
    def move(x:, y:, steps: 1)
      from_x = @x
      from_y = @y
      @x = x
      @y = y

      steps.times do |i|
        new_x = from_x + ((@x - from_x) * ((i + 1) / steps.to_f))
        new_y = from_y + ((@y - from_y) * ((i + 1) / steps.to_f))

        @page.command("Input.dispatchMouseEvent",
                      slowmoable: true,
                      type: "mouseMoved",
                      x: new_x.to_i,
                      y: new_y.to_i)
      end

      self
    end

    private

    def mouse_event(type:, button: :left, count: 1, modifiers: nil, wait: 0)
      button = validate_button(button)
      options = { x: @x, y: @y, type: type, button: button, clickCount: count }
      options.merge!(modifiers: modifiers) if modifiers
      @page.command("Input.dispatchMouseEvent", wait: wait, slowmoable: true, **options)
    end

    def validate_button(button)
      button = button.to_s
      raise "Invalid button: #{button}" unless VALID_BUTTONS.include?(button)

      button
    end
  end
end
