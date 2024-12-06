class OAuth::CLI
  class QueryCommand < BaseCommand
    extend OAuth::Helper

    def required_options
      %i[oauth_consumer_key oauth_consumer_secret oauth_token oauth_token_secret]
    end

    def _run
      consumer = OAuth::Consumer.new(options[:oauth_consumer_key], options[:oauth_consumer_secret], scheme: options[:scheme])

      access_token = OAuth::AccessToken.new(consumer, options[:oauth_token], options[:oauth_token_secret])

      # append params to the URL
      uri = URI.parse(options[:uri])
      params = parameters.map { |k, v| Array(v).map { |v2| "#{OAuth::Helper.escape(k)}=#{OAuth::Helper.escape(v2)}" } * "&" }
      uri.query = [uri.query, *params].reject(&:nil?) * "&"
      puts uri.to_s

      response = access_token.request(options[:method].to_s.downcase.to_sym, uri.to_s)
      puts "#{response.code} #{response.message}"
      puts response.body
    end
  end
end
