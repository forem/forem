#!/usr/bin/env ruby
# frozen_string_literal: true

if $PROGRAM_NAME == __FILE__
  $LOAD_PATH << '.'
  $LOAD_PATH << '..'
  $LOAD_PATH << '../lib'
  $LOAD_PATH << '../ext'
end

require 'oj'

def sample_json(size=3)
  colors = [ :black, :gray, :white, :red, :blue, :yellow, :green, :purple, :orange ]
  container = []
  size.times do |i|
    box = {
      'color' => colors[i % colors.size],
      'fragile' => (0 == (i % 2)),
      'width' => i,
      'height' => i,
      'depth' => i,
      'weight' => i * 1.3,
      'address' => {
        'street' => "#{i} Main Street",
        'city' => 'Sity',
        'state' => nil
      }
    }
    container << box
  end
  container
end

if $PROGRAM_NAME == __FILE__
  File.write('sample.json', Oj.dump(sample_json(3), :indent => 2))
end
