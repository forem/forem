# frozen_string_literal: true
module YARD
  module Tags
    class RefTagList
      attr_accessor :owner, :tag_name, :name

      def initialize(tag_name, owner, name = nil)
        @owner = CodeObjects::Proxy === owner ? owner : P(owner)
        @tag_name = tag_name.to_s
        @name = name
      end

      def tags
        if owner.is_a?(CodeObjects::Base)
          o = owner.tags(tag_name)
          o = o.select {|t| t.name.to_s == name.to_s } if name
          o.each do |t|
            t.extend(RefTag)
            t.owner = owner
          end
          o
        else
          []
        end
      end
    end
  end
end
