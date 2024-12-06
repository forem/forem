# Used for Cornish, Inari Sami, Inuktitut, Lule Sami, Nama, Northern Sami,
# Sami Language, Skolt Sami, Southern Sami.

module RailsI18n
  module Pluralization
    module OneTwoOther
      def self.rule
        lambda do |n|
          case n
          when 1 then :one
          when 2 then :two
          else :other
          end
        end
      end

      def self.with_locale(locale)
        { locale => {
            :'i18n' => {
              :plural => {
                :keys => [:one, :two, :other],
                :rule => rule }}}}
      end
    end
  end
end
