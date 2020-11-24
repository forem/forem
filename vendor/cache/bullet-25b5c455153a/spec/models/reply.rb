# frozen_string_literal: true

class Reply < ActiveRecord::Base
  belongs_to :submission
end
