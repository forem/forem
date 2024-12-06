{
  gd: {
    number: {
      nth: {
        ordinals: -> (_key, number:, **_options) {
          case number.to_i.abs
          when 1
            'ᵈ'
          when 2
            'ⁿᵃ'
          when 3
            'ˢ'
          else
            'ᵐʰ'
          end
        },

        ordinalized:  -> (_key, number:, **_options) {
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        }
      }
    }
  }
}
