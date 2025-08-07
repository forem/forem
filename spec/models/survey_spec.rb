require 'rails_helper'

RSpec.describe Survey, type: :model do
  # has many polls association
  it { is_expected.to have_many(:polls).dependent(:nullify) }
end
