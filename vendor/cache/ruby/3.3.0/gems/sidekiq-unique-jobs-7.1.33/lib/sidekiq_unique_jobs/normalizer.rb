# frozen_string_literal: true

module SidekiqUniqueJobs
  # Normalizes hashes by dumping them to json and loading them from json
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Normalizer
    extend SidekiqUniqueJobs::JSON

    # Changes hash to a json compatible hash
    # @param [Hash] args
    # @return [Hash] a json compatible hash
    def self.jsonify(args)
      load_json(dump_json(args))
    end
  end
end
