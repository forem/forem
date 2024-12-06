require "sidekiq"
require "time"

# This file is designed to be required within the user's
# deployment script; it should need a bare minimum of dependencies.
#
#   require "sidekiq/metrics/deploy"
#   gitdesc = `git log -1 --format="%h %s"`.strip
#   d = Sidekiq::Metrics::Deploy.new
#   d.mark(label: gitdesc)
#
# Note that you cannot mark more than once per minute. This is a feature, not a bug.
module Sidekiq
  module Metrics
    class Deploy
      MARK_TTL = 90 * 24 * 60 * 60 # 90 days

      def initialize(pool = Sidekiq.redis_pool)
        @pool = pool
      end

      def mark(at: Time.now, label: "")
        # we need to round the timestamp so that we gracefully
        # handle an excepted common error in marking deploys:
        # having every process mark its deploy, leading
        # to N marks for each deploy. Instead we round the time
        # to the minute so that multple marks within that minute
        # will all naturally rollup into one mark per minute.
        whence = at.utc
        floor = Time.utc(whence.year, whence.month, whence.mday, whence.hour, whence.min, 0)
        datecode = floor.strftime("%Y%m%d")
        key = "#{datecode}-marks"
        @pool.with do |c|
          c.pipelined do |pipe|
            pipe.hsetnx(key, floor.iso8601, label)
            pipe.expire(key, MARK_TTL)
          end
        end
      end

      def fetch(date = Time.now.utc.to_date)
        datecode = date.strftime("%Y%m%d")
        @pool.with { |c| c.hgetall("#{datecode}-marks") }
      end
    end
  end
end
