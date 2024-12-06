# frozen_string_literal: true

module Emoji
  class Character
    # Inspect individual Unicode characters in a string by dumping its
    # codepoints in hexadecimal format.
    def self.hex_inspect(str)
      str.codepoints.map { |c| c.to_s(16).rjust(4, '0') }.join('-')
    end

    # True if the emoji is not a standard Emoji character.
    def custom?() !raw end

    # True if the emoji supports Fitzpatrick scale skin tone modifiers
    def skin_tones?() @skin_tones end

    attr_writer :skin_tones

    # A list of names uniquely referring to this emoji.
    attr_reader :aliases

    # The category for this emoji as per Apple's character palette
    attr_accessor :category

    # The Unicode description text
    attr_accessor :description

    # The Unicode spec version where this emoji first debuted
    attr_accessor :unicode_version

    # The iOS version where this emoji first debuted
    attr_accessor :ios_version

    def name() aliases.first end

    def add_alias(name)
      aliases << name
    end

    # A list of Unicode strings that uniquely refer to this emoji.
    attr_reader :unicode_aliases

    # Raw Unicode string for an emoji. Nil if emoji is non-standard.
    def raw() unicode_aliases.first end

    # Raw Unicode strings for each skin tone variant of this emoji. The result is an empty array
    # unless the emoji supports skin tones.
    #
    # Note: for emojis that depict multiple people (e.g. couples or families), this will not produce
    # every possible permutation of skin tone per person.
    def raw_skin_tone_variants
      return [] if custom? || !skin_tones?
      raw_normalized = raw.sub(VARIATION_SELECTOR_16, "")
      idx = raw_normalized.index(ZERO_WIDTH_JOINER)
      SKIN_TONES.map do |modifier|
        if raw_normalized == PEOPLE_HOLDING_HANDS
          # special case to apply the modifier to both persons
          raw_normalized[0...idx] + modifier + raw_normalized[idx..nil] + modifier
        elsif idx
          # insert modifier before zero-width joiner
          raw_normalized[0...idx] + modifier + raw_normalized[idx..nil]
        else
          raw_normalized + modifier
        end
      end
    end

    def add_unicode_alias(str)
      unicode_aliases << str
    end

    # A list of tags associated with an emoji. Multiple emojis can share the
    # same tags.
    attr_reader :tags

    def add_tag(tag)
      tags << tag
    end

    def initialize(name)
      @aliases = Array(name)
      @unicode_aliases = []
      @tags = []
      @skin_tones = false
    end

    def inspect
      hex = '(%s)' % hex_inspect unless custom?
      %(#<#{self.class.name}:#{name}#{hex}>)
    end

    def hex_inspect
      self.class.hex_inspect(raw)
    end

    attr_writer :image_filename

    def image_filename
      if defined? @image_filename
        @image_filename
      else
        default_image_filename
      end
    end

    private

    VARIATION_SELECTOR_16 = "\u{fe0f}".freeze
    ZERO_WIDTH_JOINER = "\u{200d}".freeze
    PEOPLE_HOLDING_HANDS = "\u{1f9d1}\u{200d}\u{1f91d}\u{200d}\u{1f9d1}".freeze

    SKIN_TONES = [
      "\u{1F3FB}", # light skin tone
      "\u{1F3FC}", # medium-light skin tone
      "\u{1F3FD}", # medium skin tone
      "\u{1F3FE}", # medium-dark skin tone
      "\u{1F3FF}", # dark skin tone
    ]

    private_constant :VARIATION_SELECTOR_16, :ZERO_WIDTH_JOINER, :PEOPLE_HOLDING_HANDS, :SKIN_TONES

    def default_image_filename
      if custom?
        '%s.png' % name
      else
        hex_name = hex_inspect.gsub(/-(fe0f|200d)\b/, '')
        'unicode/%s.png' % hex_name
      end
    end
  end
end
