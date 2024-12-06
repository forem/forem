# frozen_string_literal: true

require 'launchy'

Capybara::SpecHelper.spec '#save_and_open_screenshot' do
  before do
    @session.visit '/'
  end

  it 'opens file from the default directory', requires: [:screenshot] do
    expected_file_regex = /capybara-\d+\.png/
    allow(@session.driver).to receive(:save_screenshot)
    allow(Launchy).to receive(:open)

    @session.save_and_open_screenshot

    expect(@session.driver).to have_received(:save_screenshot)
      .with(expected_file_regex, any_args)
    expect(Launchy).to have_received(:open).with(expected_file_regex)
  end

  it 'opens file from the provided directory', requires: [:screenshot] do
    custom_path = 'screenshots/1.png'
    allow(@session.driver).to receive(:save_screenshot)
    allow(Launchy).to receive(:open)

    @session.save_and_open_screenshot(custom_path)

    expect(@session.driver).to have_received(:save_screenshot)
      .with(/#{custom_path}$/, any_args)
    expect(Launchy).to have_received(:open).with(/#{custom_path}$/)
  end

  context 'when launchy cannot be required' do
    it 'prints out a correct warning message', requires: [:screenshot] do
      file_path = File.join(Dir.tmpdir, 'test.png')
      allow(@session).to receive(:warn)
      allow(@session).to receive(:require).with('launchy').and_raise(LoadError)
      @session.save_and_open_screenshot(file_path)
      expect(@session).to have_received(:warn).with("File saved to #{file_path}.\nPlease install the launchy gem to open the file automatically.")
    end
  end
end
