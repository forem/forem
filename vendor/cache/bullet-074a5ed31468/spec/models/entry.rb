# frozen_string_literal: true

class Entry < ActiveRecord::Base
  belongs_to :category
end
