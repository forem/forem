# encoding: utf-8
# frozen_string_literal: true

require 'emoji/character'
require 'json'

module Emoji
  extend self

  def data_file
    File.expand_path('../../db/emoji.json', __FILE__)
  end

  def all
    return @all if defined? @all
    @all = []
    parse_data_file
    @all
  end

  # Public: Initialize an Emoji::Character instance and yield it to the block.
  # The character is added to the `Emoji.all` set.
  def create(name)
    emoji = Emoji::Character.new(name)
    self.all << edit_emoji(emoji) { yield emoji if block_given? }
    emoji
  end

  # Public: Yield an emoji to the block and update the indices in case its
  # aliases or unicode_aliases lists changed.
  def edit_emoji(emoji)
    @names_index ||= Hash.new
    @unicodes_index ||= Hash.new

    yield emoji

    emoji.aliases.each do |name|
      @names_index[name] = emoji
    end
    emoji.unicode_aliases.each do |unicode|
      @unicodes_index[unicode] = emoji
    end

    emoji
  end

  # Public: Find an emoji by its aliased name. Return nil if missing.
  def find_by_alias(name)
    names_index[name]
  end

  # Public: Find an emoji by its unicode character. Return nil if missing.
  def find_by_unicode(unicode)
    unicodes_index[unicode] || unicodes_index[unicode.sub(SKIN_TONE_RE, "")]
  end

  private
    VARIATION_SELECTOR_16 = "\u{fe0f}".freeze
    SKIN_TONE_RE = /[\u{1F3FB}-\u{1F3FF}]/

    # Characters which must have VARIATION_SELECTOR_16 to render as color emoji:
    TEXT_GLYPHS = [
      "\u{1f237}", # Japanese “monthly amount” button
      "\u{1f202}", # Japanese “service charge” button
      "\u{1f170}", # A button (blood type)
      "\u{1f171}", # B button (blood type)
      "\u{1f17e}", # O button (blood type)
      "\u{00a9}",  # copyright
      "\u{00ae}",  # registered
      "\u{2122}",  # trade mark
      "\u{3030}",  # wavy dash
    ].freeze

    private_constant :VARIATION_SELECTOR_16, :TEXT_GLYPHS, :SKIN_TONE_RE

    def parse_data_file
      data = File.open(data_file, 'r:UTF-8') do |file|
        JSON.parse(file.read, symbolize_names: true)
      end

      if "".respond_to?(:-@)
        # Ruby >= 2.3 this is equivalent to .freeze
        # Ruby >= 2.5 this will freeze and dedup
        dedup = lambda { |str| -str }
      else
        dedup = lambda { |str| str.freeze }
      end

      append_unicode = lambda do |emoji, raw|
        unless TEXT_GLYPHS.include?(raw) || emoji.unicode_aliases.include?(raw)
          emoji.add_unicode_alias(dedup.call(raw))
        end
      end

      data.each do |raw_emoji|
        self.create(nil) do |emoji|
          raw_emoji.fetch(:aliases).each { |name| emoji.add_alias(dedup.call(name)) }
          if raw = raw_emoji[:emoji]
            append_unicode.call(emoji, raw)
            start_pos = 0
            while found_index = raw.index(VARIATION_SELECTOR_16, start_pos)
              # register every variant where one VARIATION_SELECTOR_16 is removed
              raw_alternate = raw.dup
              raw_alternate[found_index] = ""
              append_unicode.call(emoji, raw_alternate)
              start_pos = found_index + 1
            end
            if start_pos > 0
              # register a variant with all VARIATION_SELECTOR_16 removed
              append_unicode.call(emoji, raw.gsub(VARIATION_SELECTOR_16, ""))
            else
              # register a variant where VARIATION_SELECTOR_16 is added
              append_unicode.call(emoji, "#{raw}#{VARIATION_SELECTOR_16}")
            end
          end
          raw_emoji.fetch(:tags).each { |tag| emoji.add_tag(dedup.call(tag)) }

          emoji.category = dedup.call(raw_emoji[:category])
          emoji.description = dedup.call(raw_emoji[:description])
          emoji.unicode_version = dedup.call(raw_emoji[:unicode_version])
          emoji.ios_version = dedup.call(raw_emoji[:ios_version])
          emoji.skin_tones = raw_emoji.fetch(:skin_tones, false)
        end
      end
    end

    def names_index
      all unless defined? @all
      @names_index
    end

    def unicodes_index
      all unless defined? @all
      @unicodes_index
    end
end

# Preload emoji into memory
Emoji.all
