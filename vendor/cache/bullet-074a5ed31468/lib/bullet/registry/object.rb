# frozen_string_literal: true

module Bullet
  module Registry
    class Object < Base
      def add(bullet_key)
        super(bullet_key.bullet_class_name, bullet_key)
      end

      def include?(bullet_key)
        super(bullet_key.bullet_class_name, bullet_key)
      end
    end
  end
end
