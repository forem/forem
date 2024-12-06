# frozen_string_literal: true

require 'octokit/response/base_middleware'

module Octokit
  module Response
    # Parses RSS and Atom feed responses.
    class FeedParser < BaseMiddleware
      def on_complete(env)
        if env[:response_headers]['content-type'] =~ /(\batom|\brss)/
          require 'rss'
          env[:body] = RSS::Parser.parse env[:body]
        end
      end
    end
  end
end
