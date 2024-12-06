# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'json'

module Benchmark
  module IPS
    class Share
      DEFAULT_URL = "https://ips.fastruby.io"
      def initialize(report, job)
        @report = report
        @job = job
      end

      def share
        base = (ENV['SHARE_URL'] || DEFAULT_URL)
        url = URI(File.join(base, "reports"))

        req = Net::HTTP::Post.new(url)

        data = {
          "entries" => @report.data,
          "options" => {
            "compare" => @job.compare?
          }
        }

        req.body = JSON.generate(data)

        http = Net::HTTP.new(url.hostname, url.port)
        if url.scheme == "https"
          http.use_ssl = true
          http.ssl_version = :TLSv1_2
        end

        res = http.start do |h|
          h.request req
        end

        if Net::HTTPOK === res
          data = JSON.parse res.body
          puts "Shared at: #{File.join(base, data["id"])}"
        else
          puts "Error sharing report"
        end
      end
    end
  end
end
