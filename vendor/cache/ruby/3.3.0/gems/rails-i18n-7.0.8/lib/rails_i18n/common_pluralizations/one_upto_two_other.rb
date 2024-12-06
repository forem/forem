# Used for French, Fulah, Kabyle.

module RailsI18n
  module Pluralization
    module OneUptoTwoOther
      def self.rule
        lambda do |n|
          n.is_a?(Numeric) && n >= 0 && n < 2 ? :one : :other
        end
      end

      def self.with_locale(locale)
        { locale => {
            :'i18n' => {
              :plural => {
                :keys => [:one, :other],
                :rule => rule }}}}
      end
    end
  end
end
