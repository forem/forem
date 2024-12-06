# frozen_string_literal: true

require "ferrum/frame/dom"
require "ferrum/frame/runtime"

module Ferrum
  class Frame
    include DOM
    include Runtime

    STATE_VALUES = %i[
      started_loading
      navigated
      stopped_loading
    ].freeze

    # The Frame's unique id.
    #
    # @return [String]
    attr_accessor :id

    # If frame was given a name it should be here.
    #
    # @return [String, nil]
    attr_accessor :name

    # The page the frame belongs to.
    #
    # @return [Page]
    attr_reader :page

    # Parent frame id if this one is nested in another one.
    #
    # @return [String, nil]
    attr_reader :parent_id

    # One of the states frame's in.
    #
    # @return [:started_loading, :navigated, :stopped_loading, nil]
    attr_reader :state

    def initialize(id, page, parent_id = nil)
      @id = id
      @page = page
      @parent_id = parent_id
      @execution_id = Concurrent::MVar.new
    end

    def state=(value)
      raise ArgumentError unless STATE_VALUES.include?(value)

      @state = value
    end

    #
    # Returns current frame's `location.href`.
    #
    # @return [String]
    #
    # @example
    #   browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
    #   frame = browser.frames[1]
    #   frame.url # => https://interactive-examples.mdn.mozilla.net/pages/tabbed/iframe.html
    #
    def url
      evaluate("document.location.href")
    end

    #
    # Returns current frame's title.
    #
    # @return [String]
    #
    # @example
    #   browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
    #   frame = browser.frames[1]
    #   frame.title # => HTML Demo: <iframe>
    #
    def title
      evaluate("document.title")
    end

    #
    # If current frame is the main frame of the page (top of the tree).
    #
    # @return [Boolean]
    #
    # @example
    #   browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
    #   frame = browser.frame_by(id: "C09C4E4404314AAEAE85928EAC109A93")
    #   frame.main? # => false
    #
    def main?
      @parent_id.nil?
    end

    #
    # Sets a content of a given frame.
    #
    # @param [String] html
    #
    # @example
    #   browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
    #   frame = browser.frames[1]
    #   frame.body # <html lang="en"><head><style>body {transition: opacity ease-in 0.2s; }...
    #   frame.content = "<html><head></head><body><p>lol</p></body></html>"
    #   frame.body # => <html><head></head><body><p>lol</p></body></html>
    #
    def content=(html)
      evaluate_async(%(
        document.open();
        document.write(arguments[0]);
        document.close();
        arguments[1](true);
      ), @page.timeout, html)
      @page.document_node_id
    end
    alias set_content content=

    #
    # Execution context id which is used by JS, each frame has it's own
    # context in which JS evaluates. Locks for a page timeout and raises
    # an error if an execution id hasn't been set yet, if id is set
    # returns immediately.
    #
    # @return [Integer]
    #
    # @raise [NoExecutionContextError]
    #
    def execution_id!
      value = @execution_id.borrow(@page.timeout, &:itself)
      raise NoExecutionContextError if value.instance_of?(Object)

      value
    end

    #
    # Execution context id which is used by JS, each frame has it's own
    # context in which JS evaluates.
    #
    # @return [Integer, nil]
    #
    def execution_id
      value = @execution_id.value
      return if value.instance_of?(Object)

      value
    end

    def execution_id=(value)
      if value.nil?
        @execution_id.try_take!
      else
        @execution_id.try_put!(value)
      end
    end

    def inspect
      "#<#{self.class} " \
        "@id=#{@id.inspect} " \
        "@parent_id=#{@parent_id.inspect} " \
        "@name=#{@name.inspect} " \
        "@state=#{@state.inspect} " \
        "@execution_id=#{@execution_id.inspect}>"
    end
  end
end
