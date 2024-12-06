# coding: US-ASCII
# frozen_string_literal: true

Capybara::SpecHelper.spec '#save_screenshot' do
  let(:image_path) { File.join(Dir.tmpdir, 'capybara-screenshot.png') }

  before do
    @session.visit '/'
  end

  it 'should generate PNG file', requires: [:screenshot] do
    path = @session.save_screenshot image_path

    magic = File.read(image_path, 4)
    expect(magic).to eq "\x89PNG"
    expect(path).to eq image_path
  end
end
