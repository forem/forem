# frozen_string_literal: true

require 'openssl'
if RUBY_VERSION > "2"
  require "ostruct"
else
  require "cloudinary/ostruct2"
end


module Cloudinary
  module AuthToken
    SEPARATOR = '~'
    UNSAFE = /[ "#%&\'\/:;<=>?@\[\\\]^`{\|}~]/
    EMPTY_TOKEN = {}.freeze

    def self.generate(options = {})
      key = options[:key]
      raise "Missing auth token key configuration" unless key
      name = options[:token_name] || "__cld_token__"
      start = options[:start_time]
      expiration = options[:expiration]
      ip = options[:ip]

      acl = options[:acl]
      if acl.present?
        acl = acl.is_a?(String) ? [acl] : acl
      end

      duration = options[:duration]
      url = options[:url]
      start = Time.new.getgm.to_i if start == 'now'
      if expiration.nil? || expiration == 0
        if !(duration.nil? || duration == 0)
          expiration = (start || Time.new.getgm.to_i) + duration
        else
          raise 'Must provide either expiration or duration'
        end
      end

      if url.blank? && acl.blank?
        raise 'AuthToken must contain either an acl or a url property'
      end

      token = []
      token << "ip=#{ip}" if ip
      token << "st=#{start}" if start
      token << "exp=#{expiration}"
      token << "acl=#{escape_to_lower(acl.join('!'))}" if acl && acl.size > 0
      to_sign = token.clone
      to_sign << "url=#{escape_to_lower(url)}" if url && (acl.blank? || acl.size == 0)
      auth = digest(to_sign.join(SEPARATOR), key)
      token << "hmac=#{auth}"
      "#{name}=#{token.join(SEPARATOR)}"
    end

    # Merge token2 to token1 returning a new
    # Requires to support Ruby 1.9
    def self.merge_auth_token(token1, token2)
      token1 = token1 || EMPTY_TOKEN
      token2 = token2 || EMPTY_TOKEN
      token1 = token1.respond_to?( :to_h) ? token1.to_h : token1
      token2 = token2.respond_to?( :to_h) ? token2.to_h : token2
      token1.merge(token2)
    end

    private

    # escape URI pattern using lowercase hex. For example "/" -> "%2f".
    def self.escape_to_lower(url)
      Utils.smart_escape(url, UNSAFE).gsub(/%[0-9A-F]{2}/) do |h|
        h.downcase
      end.force_encoding(Encoding::US_ASCII)
    end


    def self.digest(message, key)
      bin_key = Array(key).pack("H*")
      digest = OpenSSL::Digest::SHA256.new
      OpenSSL::HMAC.hexdigest(digest, bin_key, message)
    end
  end
end
