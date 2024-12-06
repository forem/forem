# frozen_string_literal: true

class String
  def bullet_class_name
    sub(/:[^:]*?$/, '')
  end
end
