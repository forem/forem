{
  de: {
    number: {
      nth: {
        ordinals: -> (_key, number:, **_options) {
          '.'
        },

        ordinalized:  -> (_key, number:, **_options) {
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        }
      }
    }
  }
}
