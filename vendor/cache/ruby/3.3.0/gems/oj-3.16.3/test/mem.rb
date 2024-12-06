#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'oj'

Oj.default_options = { mode: :rails, cache_keys: false, cache_str: -1 }

def mem
  `ps -o rss= -p #{$PROCESS_ID}`.to_i
end

('a'..'z').each { |a|
  ('a'..'z').each { |b|
    ('a'..'z').each { |c|
      ('a'..'z').each { |d|
        ('a'..'z').each { |e|
          ('a'..'z').each { |f|
            key = "#{a}#{b}#{c}#{d}#{e}#{f}"
            Oj.load(%|{ "#{key}": 101}|)
            # Oj.dump(x)
          }
        }
      }
    }
    puts "#{a}#{b} #{mem}"
  }
}

Oj::Parser.new(:usual)
