require 'rails_helper'

RSpec.describe 'Example App', :use_fixtures, type: :model do
  it 'supports fixture file upload' do
    file = fixture_file_upload(__FILE__)
    expect(file.read).to match(/RSpec\.describe 'Example App'/im)
  end
end
