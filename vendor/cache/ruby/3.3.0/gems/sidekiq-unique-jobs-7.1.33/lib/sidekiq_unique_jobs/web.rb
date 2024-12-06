# frozen_string_literal: true

require_relative "web/helpers"

module SidekiqUniqueJobs
  # Utility module to help manage unique keys in redis.
  # Useful for deleting keys that for whatever reason wasn't deleted
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Web
    def self.registered(app) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      app.helpers do
        include Web::Helpers
      end

      app.get "/changelogs" do
        @filter         = h(params[:filter] || "*")
        @filter         = "*" if @filter == ""
        @count          = h(params[:count] || 100).to_i
        @current_cursor = h(params[:cursor])
        @prev_cursor    = h(params[:prev_cursor])
        @total_size, @next_cursor, @changelogs = changelog.page(
          cursor: @current_cursor,
          pattern: @filter,
          page_size: @count,
        )

        erb(unique_template(:changelogs))
      end

      app.get "/changelogs/delete_all" do
        changelog.clear
        redirect_to :changelogs
      end

      app.get "/locks" do
        @filter         = h(params[:filter] || "*")
        @filter         = "*" if @filter == ""
        @count          = h(params[:count] || 100).to_i
        @current_cursor = h(params[:cursor])
        @prev_cursor    = h(params[:prev_cursor])

        @total_size, @next_cursor, @locks = digests.page(
          cursor: @current_cursor,
          pattern: @filter,
          page_size: @count,
        )

        erb(unique_template(:locks))
      end

      app.get "/expiring_locks" do
        @filter         = h(params[:filter] || "*")
        @filter         = "*" if @filter == ""
        @count          = h(params[:count] || 100).to_i
        @current_cursor = h(params[:cursor])
        @prev_cursor    = h(params[:prev_cursor])

        @total_size, @next_cursor, @locks = expiring_digests.page(
          cursor: @current_cursor,
          pattern: @filter,
          page_size: @count,
        )

        erb(unique_template(:locks))
      end

      app.get "/locks/delete_all" do
        digests.delete_by_pattern("*", count: digests.count)
        expiring_digests.delete_by_pattern("*", count: digests.count)
        redirect_to :locks
      end

      app.get "/locks/:digest" do
        @digest = h(params[:digest])
        @lock   = SidekiqUniqueJobs::Lock.new(@digest)

        erb(unique_template(:lock))
      end

      app.get "/locks/:digest/delete" do
        digests.delete_by_digest(params[:digest])
        expiring_digests.delete_by_digest(params[:digest])
        redirect_to :locks
      end

      app.get "/locks/:digest/jobs/:job_id/delete" do
        @digest = h(params[:digest])
        @job_id = h(params[:job_id])
        @lock   = SidekiqUniqueJobs::Lock.new(@digest)
        @lock.unlock(@job_id)

        redirect_to "locks/#{@lock.key}"
      end
    end
  end
end

begin
  require "delegate" unless defined?(DelegateClass)
  require "sidekiq/web" unless defined?(Sidekiq::Web)

  Sidekiq::Web.register(SidekiqUniqueJobs::Web)
  Sidekiq::Web.tabs["Locks"]          = "locks"
  Sidekiq::Web.tabs["Expiring Locks"] = "expiring_locks"
  Sidekiq::Web.tabs["Changelogs"]     = "changelogs"
  Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), "locales")
rescue NameError, LoadError => ex
  SidekiqUniqueJobs.logger.error(ex)
end
