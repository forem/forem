# frozen_string_literal: true

require 'oj'

extras = { 'locationLng' => -97.14690769100295 }

Oj.default_options = { float_precision: 17 }

encoded = Oj.dump(extras)
puts encoded
puts Oj.load(encoded)

require 'active_record'

Oj::Rails.set_encoder()
Oj::Rails.set_decoder()

Oj.default_options = { float_precision: 17 }
# Using Oj rails encoder, gets the correct value: { 'locationLng':-97.14690769100295 }
encoded = ActiveSupport::JSON.encode(extras)
puts encoded
puts ActiveSupport::JSON.decode(encoded)
puts Oj.load(encoded)
