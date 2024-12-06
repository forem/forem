# frozen_string_literal: true

module Solargraph
  # A collection of additional data, such as map pins and required paths, that
  # can be added to an ApiMap.
  #
  # Conventions are used to add Environs.
  #
  class Environ
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<String>]
    attr_reader :domains

    # @return [Array<Pin::Reference::Override>]
    attr_reader :pins

    # @param requires [Array<String>]
    # @param domains [Array<String>]
    # @param pins [Array<Pin::Base>]
    def initialize requires: [], domains: [], pins: []
      @requires = requires
      @domains = domains
      @pins = pins
    end

    # @return [self]
    def clear
      domains.clear
      requires.clear
      pins.clear
      self
    end

    # @param other [Environ]
    # @return [self]
    def merge other
      domains.concat other.domains
      requires.concat other.requires
      pins.concat other.pins
      self
    end
  end
end
