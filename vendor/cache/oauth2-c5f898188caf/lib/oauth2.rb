# includes modules from stdlib
require 'cgi'
require 'time'

# includes gem files
require 'oauth2/error'
require 'oauth2/snaky_hash'
require 'oauth2/authenticator'
require 'oauth2/client'
require 'oauth2/strategy/base'
require 'oauth2/strategy/auth_code'
require 'oauth2/strategy/implicit'
require 'oauth2/strategy/password'
require 'oauth2/strategy/client_credentials'
require 'oauth2/strategy/assertion'
require 'oauth2/access_token'
require 'oauth2/mac_token'
require 'oauth2/response'

# The namespace of this library
module OAuth2
end
