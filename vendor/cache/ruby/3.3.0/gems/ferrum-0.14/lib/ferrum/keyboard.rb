# frozen_string_literal: true

require "json"

module Ferrum
  class Keyboard
    KEYS = JSON.parse(File.read(File.expand_path("keyboard.json", __dir__)))
    MODIFIERS = { "alt" => 1, "ctrl" => 2, "control" => 2,
                  "meta" => 4, "command" => 4, "shift" => 8 }.freeze
    KEYS_MAPPING = {
      cancel: "Cancel", help: "Help", backspace: "Backspace", tab: "Tab",
      clear: "Clear", return: "Enter", enter: "Enter", shift: "Shift",
      ctrl: "Control", control: "Control", alt: "Alt", pause: "Pause",
      escape: "Escape", space: "Space", pageup: "PageUp", page_up: "PageUp",
      pagedown: "PageDown", page_down: "PageDown", end: "End", home: "Home",
      left: "ArrowLeft", up: "ArrowUp", right: "ArrowRight",
      down: "ArrowDown", insert: "Insert", delete: "Delete",
      semicolon: "Semicolon", equals: "Equal", numpad0: "Numpad0",
      numpad1: "Numpad1", numpad2: "Numpad2", numpad3: "Numpad3",
      numpad4: "Numpad4", numpad5: "Numpad5", numpad6: "Numpad6",
      numpad7: "Numpad7", numpad8: "Numpad8", numpad9: "Numpad9",
      multiply: "NumpadMultiply", add: "NumpadAdd",
      separator: "NumpadDecimal", subtract: "NumpadSubtract",
      decimal: "NumpadDecimal", divide: "NumpadDivide", f1: "F1", f2: "F2",
      f3: "F3", f4: "F4", f5: "F5", f6: "F6", f7: "F7", f8: "F8", f9: "F9",
      f10: "F10", f11: "F11", f12: "F12", meta: "Meta", command: "Meta"
    }.freeze

    def initialize(page)
      @page = page
    end

    #
    # Dispatches a `keydown` event.
    #
    # @param [String, Symbol] key
    #   Name of the key, such as `"a"`, `:enter`, or `:backspace`.
    #
    # @return [self]
    #
    def down(key)
      key = normalize_keys(Array(key)).first
      type = key[:text] ? "keyDown" : "rawKeyDown"
      @page.command("Input.dispatchKeyEvent", slowmoable: true, type: type, **key)
      self
    end

    #
    # Dispatches a `keyup` event.
    #
    # @param [String, Symbol] key
    #   Name of the key, such as `"a"`, `:enter`, or `:backspace`.
    #
    # @return [self]
    #
    def up(key)
      key = normalize_keys(Array(key)).first
      @page.command("Input.dispatchKeyEvent", slowmoable: true, type: "keyUp", **key)
      self
    end

    #
    # Sends a keydown, keypress/input, and keyup event for each character in
    # the text.
    #
    # @param [Array<String, Symbol, (Symbol, String)>] keys
    #   The text to type into a focused element, `[:Shift, "s"], "tring"`.
    #
    # @return [self]
    #
    def type(*keys)
      keys = normalize_keys(Array(keys))

      keys.each do |key|
        type = key[:text] ? "keyDown" : "rawKeyDown"
        @page.command("Input.dispatchKeyEvent", type: type, **key)
        @page.command("Input.dispatchKeyEvent", slowmoable: true, type: "keyUp", **key)
      end

      self
    end

    #
    # Returns bitfield for a given keys.
    #
    # @param [Array<:alt, :ctrl, :command, :shift>] keys
    #
    # @return [Integer]
    #
    def modifiers(keys)
      keys.map { |k| MODIFIERS[k.to_s] }.compact.reduce(0, :|)
    end

    private

    # TODO: Refactor it, and try to simplify complexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def normalize_keys(keys, pressed_keys = [], memo = [])
      case keys
      when Array
        raise ArgumentError, "empty keys passed" if keys.empty?

        pressed_keys.push([])
        memo += combine_strings(keys).map do |key|
          normalize_keys(key, pressed_keys, memo)
        end
        pressed_keys.pop
        memo.flatten.compact
      when Symbol
        key = keys.to_s.downcase

        if MODIFIERS.keys.include?(key)
          pressed_keys.last.push(key)
          nil
        else
          key = KEYS.fetch(KEYS_MAPPING[key.to_sym] || key.to_sym)
          key[:modifiers] = pressed_keys.flatten.map { |k| MODIFIERS[k] }.reduce(0, :|)
          to_options(key)
        end
      when String
        raise ArgumentError, "empty keys passed" if keys.empty?

        pressed = pressed_keys.flatten
        keys.each_char.map do |char|
          key = KEYS[char] || {}

          if pressed.empty?
            key = key.merge(text: char, unmodifiedText: char)
            [to_options(key)]
          else
            text = pressed == ["shift"] ? char.upcase : char
            key = key.merge(
              text: text,
              unmodifiedText: text,
              isKeypad: key["location"] == 3,
              modifiers: pressed.map { |k| MODIFIERS[k] }.reduce(0, :|)
            )

            modifiers = pressed.map { |k| to_options(KEYS.fetch(KEYS_MAPPING[k.to_sym])) }
            modifiers + [to_options(key)]
          end.flatten
        end
      else
        raise ArgumentError, "unexpected argument"
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    def combine_strings(keys)
      keys
        .chunk { |k| k.is_a?(String) }
        .map { |s, k| s ? [k.reduce(&:+)] : k }
        .reduce(&:+)
    end

    def to_options(hash)
      hash.inject({}) { |memo, (k, v)| memo.merge(k.to_sym => v) }
    end
  end
end
