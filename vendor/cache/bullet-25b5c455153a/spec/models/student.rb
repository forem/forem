# frozen_string_literal: true

class Student < ActiveRecord::Base
  has_and_belongs_to_many :teachers
end
