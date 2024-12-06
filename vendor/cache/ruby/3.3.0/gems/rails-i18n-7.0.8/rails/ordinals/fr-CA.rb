{
  "fr-CA": {
    number: {
      nth: {
        ordinals: -> (_key, number:, **_options) {
          if number.to_i.abs == 1
            'er'
          else
            'e'
          end
        },

        ordinalized:  -> (_key, number:, **_options) {
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        }
      }
    }
  }
}
