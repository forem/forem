require 'net-http2/callbacks'
require 'net-http2/client'
require 'net-http2/response'
require 'net-http2/request'
require 'net-http2/socket'
require 'net-http2/stream'
require 'net-http2/version'

module NetHttp2
  raise "Cannot require NetHttp2, unsupported engine '#{RUBY_ENGINE}'" unless RUBY_ENGINE == "ruby"
end
