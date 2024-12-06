module RailsI18n
  module Pluralization
    module Slovenian
      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          case n % 100
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

{ :sl => {
    :'i18n' => {
      :plural => {
        :keys => [:one, :two, :few, :other],
        :rule => RailsI18n::Pluralization::Slovenian.rule }}}}
