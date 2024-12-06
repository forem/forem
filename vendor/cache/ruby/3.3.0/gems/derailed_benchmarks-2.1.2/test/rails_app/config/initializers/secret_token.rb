# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
if Dummy::Application.config.respond_to?(:secret_key_base)
  Dummy::Application.config.secret_key_base = 'bedc31c5fff702ea808045bbbc5123455f1c00ecd005a1f667a5f04332100a6abf22cfcee2b3d39b8f677c03bb6503cf1c3b65c1287b9e13bd0d20c6431ec6ab'
else
  Dummy::Application.config.secret_token = 'bedc31c5fff702ea808045bbbc5123455f1c00ecd005a1f667a5f04332100a6abf22cfcee2b3d39b8f677c03bb6503cf1c3b65c1287b9e13bd0d20c6431ec6ab'
end
