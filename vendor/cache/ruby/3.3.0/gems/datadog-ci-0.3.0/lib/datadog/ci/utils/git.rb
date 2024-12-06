# frozen_string_literal: true

module Datadog
  module CI
    module Utils
      module Git
        def self.normalize_ref(ref)
          return nil if ref.nil?

          refs = %r{^refs/(heads/)?}
          origin = %r{^origin/}
          tags = %r{^tags/}
          ref.gsub(refs, "").gsub(origin, "").gsub(tags, "")
        end

        def self.is_git_tag?(ref)
          !ref.nil? && ref.include?("tags/")
        end
      end
    end
  end
end
