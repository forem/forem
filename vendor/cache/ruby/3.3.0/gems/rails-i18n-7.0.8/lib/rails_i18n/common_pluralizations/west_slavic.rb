# Used for Czech, Slovak.

module RailsI18n
  module Pluralization
    module WestSlavic
      def self.rule
        lambda do |n|
          case n
          when 1 then :one
          when 2, 3, 4 then :few
          else :other
          end
        end
      end

      def self.with_locale(locale)
        { locale => {
            :'i18n' => {
              :plural => {
                :keys => [:one, :few, :other],
                :rule => rule }}}}
      end
    end
  end
end
