# frozen_string_literal: true

require "ferrum/target"

module Ferrum
  class Context
    POSITION = %i[first last].freeze

    attr_reader :id, :targets

    def initialize(browser, contexts, id)
      @id = id
      @browser = browser
      @contexts = contexts
      @targets = Concurrent::Map.new
      @pendings = Concurrent::MVar.new
    end

    def default_target
      @default_target ||= create_target
    end

    def page
      default_target.page
    end

    def pages
      @targets.values.map(&:page)
    end

    # When we call `page` method on target it triggers ruby to connect to given
    # page by WebSocket, if there are many opened windows but we need only one
    # it makes more sense to get and connect to the needed one only which
    # usually is the last one.
    def windows(pos = nil, size = 1)
      raise ArgumentError if pos && !POSITION.include?(pos)

      windows = @targets.values.select(&:window?)
      windows = windows.send(pos, size) if pos
      windows.map(&:page)
    end

    def create_page(**options)
      target = create_target
      target.page = target.build_page(**options)
    end

    def create_target
      @browser.command("Target.createTarget",
                       browserContextId: @id,
                       url: "about:blank")
      target = @pendings.take(@browser.timeout)
      raise NoSuchTargetError unless target.is_a?(Target)

      @targets.put_if_absent(target.id, target)
      target
    end

    def add_target(params)
      target = Target.new(@browser, params)
      if target.window?
        @targets.put_if_absent(target.id, target)
      else
        @pendings.put(target, @browser.timeout)
      end
    end

    def update_target(target_id, params)
      @targets[target_id].update(params)
    end

    def delete_target(target_id)
      @targets.delete(target_id)
    end

    def dispose
      @contexts.dispose(@id)
    end

    def target?(target_id)
      !!@targets[target_id]
    end

    def inspect
      %(#<#{self.class} @id=#{@id.inspect} @targets=#{@targets.inspect} @default_target=#{@default_target.inspect}>)
    end
  end
end
