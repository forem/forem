# frozen_string_literal: true

module Feedjira
  module Parser
    class GloballyUniqueIdentifier
      include SAXMachine

      attribute :isPermaLink, as: :is_perma_link

      value :guid

      def perma_link?
        is_perma_link != "false"
      end

      def url
        perma_link? ? guid : nil
      end
    end
  end
end
