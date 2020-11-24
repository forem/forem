# frozen_string_literal: true

class Pet < ActiveRecord::Base
  belongs_to :person, counter_cache: true
end
