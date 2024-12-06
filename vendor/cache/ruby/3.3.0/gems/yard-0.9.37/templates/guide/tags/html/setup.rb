# frozen_string_literal: true
include T('default/tags/html')

def init
  super
  [:since, :see, :return].each do |section|
    sections[:index].delete(section)
  end
end
