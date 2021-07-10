require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Forem < OmniAuth::Strategies::OAuth2
      option :name, :forem

      option :client_options, {
        site: "http://localhost:3001",
        proxy: ENV['http_proxy'] ? URI(ENV['http_proxy']) : nil
      }

      uid { raw_info["id"] }

      info do
        {
          email: raw_info["email"]
          # and anything else you want to return to your API consumers
        }
      end

      # receive parameters from the strategy declaration and save them
      # def initialize(app, secret)
      #   @secret = secret
      #   super(app, :forem, options)
      # end

      # redirect to the Pixelation website
      # def request_phase
      #   r = Rack::Response.new
      #   r.redirect "http://localhost:3001/oauth/authorize"
      #   r.finish
      # end

      def callback_phase
        puts "********"
        uid, username, avatar, token = request.params["uid"], request.params["username"], request.params["avatar"], request.params["token"]
        sha1 = Digest::SHA1.hexdigest("a mix of  #{@secret}, #{uid}, #{username}, #{avatar}")

        # check if the request comes from Pixelation or not
        if sha1 == token
          @uid, @username, @avatar = uid, username, avatar
          # OmniAuth takes care of the rest
          super
        else
          # OmniAuth takes care of the rest
          fail!(:invalid_credentials)
        end
      end


      def raw_info
        @raw_info ||= access_token.get("/api/v0/me").parsed
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
