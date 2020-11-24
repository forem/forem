# frozen_string_literal: true

class Teacher < ActiveRecord::Base
  has_and_belongs_to_many :students
end
