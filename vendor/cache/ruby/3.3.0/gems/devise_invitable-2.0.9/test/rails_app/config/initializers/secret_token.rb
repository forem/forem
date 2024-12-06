# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
if Rails.version < '5.2.0'
  RailsApp::Application.config.secret_token = 'e997edf9d7eba5cf89a76a046fa53f5d66261d22cfcf29e3f538c75ad2d175b106bd5d099f44f6ce34ad3b3162d71cfaa37d2d4f4b38645288331427b4c2a607'
end