module RailsI18n
  module Pluralization
    module UpperSorbian
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          mod100 = n % 100

          case mod100
          when 1 then :one
          when 2 then :two
          when 3, 4 then :few
          else :other
          end
        end
      end
    end
  end
end

{ :hsb => {
    :'i18n' => {
      :plural => {
        :keys => [:one, :two, :few, :other],
        :rule => RailsI18n::Pluralization::UpperSorbian.rule }}}}
