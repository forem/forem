# frozen_string_literal: true

require "sequel"

module Honeycomb
  # Wrap sequel commands in a span
  module Sequel
    def honeycomb_client
      @honeycomb_client || Honeycomb.client
    end

    def honeycomb_client=(client)
      @honeycomb_client = client
    end

    def log_connection_yield(sql, conn, args = nil)
      return super if honeycomb_client.nil?

      honeycomb_client.start_span(name: sql.sub(/\s+.*/, "").upcase) do |span|
        span.add_field "meta.package", "sequel"
        span.add_field "meta.package_version", ::Sequel::VERSION
        span.add_field "type", "db"
        span.add_field "db.sql", sql
        super
      end
    end
  end
end

Sequel::Database.register_extension(:honeycomb, Honeycomb::Sequel)
Sequel::Database.extension :honeycomb
