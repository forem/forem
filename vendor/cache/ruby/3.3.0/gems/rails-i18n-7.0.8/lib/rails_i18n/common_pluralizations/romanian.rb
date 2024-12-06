# Used for Moldavian, Romanian.

module RailsI18n
  module Pluralization
    module Romanian
      FROM_1_TO_19 = (1..19).to_a.freeze

      def self.rule
        lambda do |n|
          return :other unless n.is_a?(Numeric)

          if n == 1
            :one
          elsif n == 0 || FROM_1_TO_19.include?(n % 100)
            :few
          else
            :other
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
