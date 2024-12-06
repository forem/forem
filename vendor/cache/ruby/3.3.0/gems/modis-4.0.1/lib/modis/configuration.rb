# frozen_string_literal: true

module Modis
  def self.configure
    yield config
  end

  class Configuration < Struct.new(:namespace)
  end

  class << self
    attr_reader :config
  end

  @config = Configuration.new
end
