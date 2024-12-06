# frozen_string_literal: true

module Anyway
  module Loaders
    class Base
      include Tracing

      class << self
        def call(local: Anyway::Settings.use_local_files, **opts)
          new(local: local).call(**opts)
        end
      end

      def initialize(local:)
        @local = local
      end

      def use_local?() = @local == true
    end
  end
end
