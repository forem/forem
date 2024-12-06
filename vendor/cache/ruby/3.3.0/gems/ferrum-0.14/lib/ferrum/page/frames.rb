# frozen_string_literal: true

require "ferrum/frame"

module Ferrum
  class Page
    module Frames
      # The page's main frame, the top of the tree and the parent of all frames.
      #
      # @return [Frame]
      attr_reader :main_frame

      #
      # Returns all the frames current page have.
      #
      # @return [Array<Frame>]
      #
      # @example
      #   browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
      #   browser.frames # =>
      #   # [
      #   #   #<Ferrum::Frame
      #   #     @id="C6D104CE454A025FBCF22B98DE612B12"
      #   #     @parent_id=nil @name=nil @state=:stopped_loading @execution_id=1>,
      #   #   #<Ferrum::Frame
      #   #     @id="C09C4E4404314AAEAE85928EAC109A93"
      #   #     @parent_id="C6D104CE454A025FBCF22B98DE612B12" @state=:stopped_loading @execution_id=2>,
      #   #   #<Ferrum::Frame
      #   #     @id="2E9C7F476ED09D87A42F2FEE3C6FBC3C"
      #   #     @parent_id="C6D104CE454A025FBCF22B98DE612B12" @state=:stopped_loading @execution_id=3>,
      #   #   ...
      #   # ]
      #
      def frames
        @frames.values
      end

      #
      # Find frame by given options.
      #
      # @param [String] id
      #   Unique frame's id that browser provides.
      #
      # @param [String] name
      #   Frame's name if there's one.
      #
      # @param [String] execution_id
      #   Frame's context execution id.
      #
      # @return [Frame, nil]
      #   The matching frame.
      #
      # @example
      #   browser.frame_by(id: "C6D104CE454A025FBCF22B98DE612B12")
      #
      def frame_by(id: nil, name: nil, execution_id: nil)
        if id
          @frames[id]
        elsif name
          frames.find { |f| f.name == name }
        elsif execution_id
          frames.find { |f| f.execution_id == execution_id }
        else
          raise ArgumentError
        end
      end

      def frames_subscribe
        subscribe_frame_attached
        subscribe_frame_detached
        subscribe_frame_started_loading
        subscribe_frame_navigated
        subscribe_frame_stopped_loading

        subscribe_navigated_within_document

        subscribe_request_will_be_sent

        subscribe_execution_context_created
        subscribe_execution_context_destroyed
        subscribe_execution_contexts_cleared
      end

      private

      def subscribe_frame_attached
        on("Page.frameAttached") do |params|
          parent_frame_id, frame_id = params.values_at("parentFrameId", "frameId")
          @frames.put_if_absent(frame_id, Frame.new(frame_id, self, parent_frame_id))
        end
      end

      def subscribe_frame_detached
        on("Page.frameDetached") do |params|
          frame = @frames[params["frameId"]]

          if frame&.main?
            frame.execution_id = nil
          else
            @frames.delete(params["frameId"])
          end
        end
      end

      def subscribe_frame_started_loading
        on("Page.frameStartedLoading") do |params|
          frame = @frames[params["frameId"]]
          frame.state = :started_loading if frame
          @event.reset
        end
      end

      def subscribe_frame_navigated
        on("Page.frameNavigated") do |params|
          frame_id, name = params["frame"]&.values_at("id", "name")
          frame = @frames[frame_id]

          if frame
            frame.state = :navigated
            frame.name = name
          end
        end
      end

      def subscribe_frame_stopped_loading
        on("Page.frameStoppedLoading") do |params|
          # `DOM.performSearch` doesn't work without getting #document node first.
          # It returns node with nodeId 1 and nodeType 9 from which descend the
          # tree and we save it in a variable because if we call that again root
          # node will change the id and all subsequent nodes have to change id too.
          if @main_frame.id == params["frameId"]
            @event.set if idling?
            document_node_id
          end

          frame = @frames[params["frameId"]]
          frame.state = :stopped_loading

          @event.set if idling?
        end
      end

      def subscribe_navigated_within_document
        on("Page.navigatedWithinDocument") do
          @event.set if idling?
        end
      end

      def subscribe_request_will_be_sent
        on("Network.requestWillBeSent") do |params|
          # Possible types:
          # Document, Stylesheet, Image, Media, Font, Script, TextTrack, XHR,
          # Fetch, EventSource, WebSocket, Manifest, SignedExchange, Ping,
          # CSPViolationReport, Other
          @event.reset if params["frameId"] == @main_frame.id && params["type"] == "Document"
        end
      end

      def subscribe_execution_context_created
        on("Runtime.executionContextCreated") do |params|
          context_id = params.dig("context", "id")
          frame_id = params.dig("context", "auxData", "frameId")

          unless @main_frame.id
            root_frame = command("Page.getFrameTree").dig("frameTree", "frame", "id")
            if frame_id == root_frame
              @main_frame.id = frame_id
              @frames.put_if_absent(frame_id, @main_frame)
            end
          end

          frame = @frames.fetch_or_store(frame_id, Frame.new(frame_id, self))
          frame.execution_id = context_id
        end
      end

      def subscribe_execution_context_destroyed
        on("Runtime.executionContextDestroyed") do |params|
          execution_id = params["executionContextId"]
          frame = frame_by(execution_id: execution_id)
          frame&.execution_id = nil
        end
      end

      def subscribe_execution_contexts_cleared
        on("Runtime.executionContextsCleared") do
          @frames.each_value { |f| f.execution_id = nil }
        end
      end

      def idling?
        @frames.values.all? { |f| f.state == :stopped_loading }
      end
    end
  end
end
