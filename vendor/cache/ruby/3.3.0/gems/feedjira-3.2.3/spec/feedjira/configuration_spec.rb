# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Configuration do
  describe ".configure" do
    it "sets strip_whitespace config" do
      Feedjira.configure { |config| config.strip_whitespace = true }
      expect(Feedjira.strip_whitespace).to be true
    end

    it "allows parsers to be modified" do
      custom_parser = Class.new

      Feedjira.configure { |config| config.parsers.unshift(custom_parser) }
      expect(Feedjira.parsers.first).to eq(custom_parser)
      Feedjira.reset_configuration!
    end
  end
end
