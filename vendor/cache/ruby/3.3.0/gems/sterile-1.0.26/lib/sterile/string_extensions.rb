# encoding: UTF-8

module Sterile

  module StringExtensions
    def self.included(base)
      Sterile.methods(false).each do |method|
        eval("def #{method}(*args, &block); Sterile.#{method}(self, *args, &block); end")
        eval("def #{method}!(*args, &block); replace Sterile.#{method}(self, *args, &block); end")
      end
    end
  end

end


class String
  include Sterile::StringExtensions
end