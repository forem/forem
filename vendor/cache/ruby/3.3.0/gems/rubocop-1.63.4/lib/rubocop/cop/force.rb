# frozen_string_literal: true

module RuboCop
  module Cop
    # A scaffold for concrete forces.
    class Force
      attr_reader :cops

      def self.all
        @all ||= []
      end

      def self.inherited(subclass)
        super
        all << subclass
      end

      def self.force_name
        name.split('::').last
      end

      def initialize(cops)
        @cops = cops
      end

      def name
        self.class.force_name
      end

      def run_hook(method_name, *args)
        cops.each do |cop|
          next unless cop.respond_to?(method_name)

          cop.public_send(method_name, *args)
        end
      end

      def investigate(_processed_source)
        # Do custom processing and invoke #run_hook at arbitrary timing.
      end
    end
  end
end
