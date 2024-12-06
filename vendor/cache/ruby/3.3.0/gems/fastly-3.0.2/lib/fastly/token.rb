# frozen_string_literal: true

# Token object
class Fastly
  class Token < Base
    attr_accessor :id, :access_token, :user_id, :services, :name,  :scope, :created_at, :last_used_at, :expires_at, :ip, :user_agent
    
    private

    def self.get_path(*_args)
      '/tokens'
    end

    def self.post_path(*_args)
      '/tokens'
    end
    
    def self.delete_path(opts)
      "/tokens/#{opts.id}"
    end
  end

  def new_token(opts)
    if client.fully_authed?
      opts[:username] = client.user
      opts[:password] = client.password
      opts[:include_auth] = false
      
      token = create(Token, opts)
      token.nil? ? nil : token
    else
      raise ArgumentError, "Required options missing. Please pass :api_key, :user and :password." 
    end
  end

  def customer_tokens(opts)
    hash = client.get("/customer/#{opts[:customer_id]}/tokens")
    hash.map { |token_hash| Token.new(token_hash, Fastly::Fetcher) }
  end
end
