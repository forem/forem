require 'bundler/setup'
require 'flipper'
require 'minitest/autorun'
require 'minitest/unit'
Dir['./lib/flipper/test/*.rb'].sort.each { |f| require(f) }

FlipperRoot = Pathname(__FILE__).dirname.join('..').expand_path
