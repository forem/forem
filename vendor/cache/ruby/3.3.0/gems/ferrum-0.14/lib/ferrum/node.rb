# frozen_string_literal: true

module Ferrum
  class Node
    MOVING_WAIT_DELAY = ENV.fetch("FERRUM_NODE_MOVING_WAIT", 0.01).to_f
    MOVING_WAIT_ATTEMPTS = ENV.fetch("FERRUM_NODE_MOVING_ATTEMPTS", 50).to_i

    attr_reader :page, :target_id, :node_id, :description, :tag_name

    def initialize(frame, target_id, node_id, description)
      @page = frame.page
      @target_id = target_id
      @node_id = node_id
      @description = description
      @tag_name = description["nodeName"].downcase
    end

    def node?
      description["nodeType"] == 1 # nodeType: 3, nodeName: "#text" e.g.
    end

    def frame_id
      description["frameId"]
    end

    def frame
      page.frame_by(id: frame_id)
    end

    def focus
      tap { page.command("DOM.focus", slowmoable: true, nodeId: node_id) }
    end

    def focusable?
      focus
      true
    rescue BrowserError => e
      e.message == "Element is not focusable" ? false : raise
    end

    def wait_for_stop_moving(delay: MOVING_WAIT_DELAY, attempts: MOVING_WAIT_ATTEMPTS)
      Utils::Attempt.with_retry(errors: NodeMovingError, max: attempts, wait: 0) do
        previous, current = content_quads_with(delay: delay)
        raise NodeMovingError.new(self, previous, current) if previous != current

        current
      end
    end

    def moving?(delay: MOVING_WAIT_DELAY)
      previous, current = content_quads_with(delay: delay)
      previous == current
    end

    def blur
      tap { evaluate("this.blur()") }
    end

    def type(*keys)
      tap { page.keyboard.type(*keys) }
    end

    # mode: (:left | :right | :double)
    # keys: (:alt, (:ctrl | :control), (:meta | :command), :shift)
    # offset: { :x, :y, :position (:top | :center) }
    def click(mode: :left, keys: [], offset: {}, delay: 0)
      x, y = find_position(**offset)
      modifiers = page.keyboard.modifiers(keys)

      case mode
      when :right
        page.mouse.move(x: x, y: y)
        page.mouse.down(button: :right, modifiers: modifiers)
        sleep(delay)
        page.mouse.up(button: :right, modifiers: modifiers)
      when :double
        page.mouse.move(x: x, y: y)
        page.mouse.down(modifiers: modifiers, count: 2)
        page.mouse.up(modifiers: modifiers, count: 2)
      when :left
        page.mouse.click(x: x, y: y, modifiers: modifiers, delay: delay)
      end

      self
    end

    def hover
      raise NotImplementedError
    end

    def scroll_into_view
      tap { page.command("DOM.scrollIntoViewIfNeeded", nodeId: node_id) }
    end

    def in_viewport?(of: nil)
      function = <<~JS
        function(element, scope) {
          const rect = element.getBoundingClientRect();
          const [height, width] = scope
            ? [scope.offsetHeight, scope.offsetWidth]
            : [window.innerHeight, window.innerWidth];
          return rect.top >= 0 &&
           rect.left >= 0 &&
           rect.bottom <= height &&
           rect.right <= width;
        }
      JS
      page.evaluate_func(function, self, of)
    end

    def select_file(value)
      page.command("DOM.setFileInputFiles", slowmoable: true, nodeId: node_id, files: Array(value))
    end

    def at_xpath(selector)
      page.at_xpath(selector, within: self)
    end

    def at_css(selector)
      page.at_css(selector, within: self)
    end

    def xpath(selector)
      page.xpath(selector, within: self)
    end

    def css(selector)
      page.css(selector, within: self)
    end

    def text
      evaluate("this.textContent")
    end

    # FIXME: clear API for text and inner_text
    def inner_text
      evaluate("this.innerText")
    end

    def value
      evaluate("this.value")
    end

    def property(name)
      evaluate("this['#{name}']")
    end
    alias [] property

    def attribute(name)
      evaluate("this.getAttribute('#{name}')")
    end

    def selected
      function = <<~JS
        function(element) {
          if (element.nodeName.toLowerCase() !== 'select') {
            throw new Error('Element is not a <select> element.');
          }
          return Array.from(element).filter(option => option.selected);
        }
      JS
      page.evaluate_func(function, self, on: self)
    end

    def select(*values, by: :value)
      tap do
        function = <<~JS
          function(element, values, by) {
            if (element.nodeName.toLowerCase() !== 'select') {
              throw new Error('Element is not a <select> element.');
            }
            const options = Array.from(element.options);
            element.value = undefined;
            for (const option of options) {
              option.selected = values.some((value) => option[by] === value);
              if (option.selected && !element.multiple) break;
            }
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
          }
        JS
        page.evaluate_func(function, self, values.flatten, by, on: self)
      end
    end

    def evaluate(expression)
      page.evaluate_on(node: self, expression: expression)
    end

    def ==(other)
      return false unless other.is_a?(Node)

      # We compare backendNodeId because once nodeId is sent to frontend backend
      # never returns same nodeId sending 0. In other words frontend is
      # responsible for keeping track of node ids.
      target_id == other.target_id && description["backendNodeId"] == other.description["backendNodeId"]
    end

    def inspect
      %(#<#{self.class} @target_id=#{@target_id.inspect} @node_id=#{@node_id} @description=#{@description.inspect}>)
    end

    def find_position(x: nil, y: nil, position: :top)
      points = wait_for_stop_moving.map { |q| to_points(q) }.first
      get_position(points, x, y, position)
    rescue CoordinatesNotFoundError
      x, y = bounding_rect_coordinates
      raise if x.zero? && y.zero?

      [x, y]
    end

    # Returns a hash of the computed styles for the node
    def computed_style
      page
        .command("CSS.getComputedStyleForNode", nodeId: node_id)["computedStyle"]
        .each_with_object({}) { |style, memo| memo.merge!(style["name"] => style["value"]) }
    end

    private

    def bounding_rect_coordinates
      evaluate <<~JS
        [this.getBoundingClientRect().left + window.pageXOffset + (this.offsetWidth / 2),
         this.getBoundingClientRect().top + window.pageYOffset + (this.offsetHeight / 2)]
      JS
    end

    def content_quads
      quads = page.command("DOM.getContentQuads", nodeId: node_id)["quads"]
      raise CoordinatesNotFoundError, "Node is either not visible or not an HTMLElement" if quads.empty?

      quads
    end

    def content_quads_with(delay: MOVING_WAIT_DELAY)
      previous = content_quads
      sleep(delay)
      current = content_quads
      [previous, current]
    end

    def get_position(points, offset_x, offset_y, position)
      x = y = nil

      if offset_x && offset_y && position == :top
        point = points.first
        x = point[:x] + offset_x.to_i
        y = point[:y] + offset_y.to_i
      else
        x, y = points.inject([0, 0]) do |memo, coordinate|
          [memo[0] + coordinate[:x],
           memo[1] + coordinate[:y]]
        end

        x /= 4
        y /= 4
      end

      if offset_x && offset_y && position == :center
        x += offset_x.to_i
        y += offset_y.to_i
      end

      [x, y]
    end

    def to_points(quad)
      [{ x: quad[0], y: quad[1] },
       { x: quad[2], y: quad[3] },
       { x: quad[4], y: quad[5] },
       { x: quad[6], y: quad[7] }]
    end
  end
end
