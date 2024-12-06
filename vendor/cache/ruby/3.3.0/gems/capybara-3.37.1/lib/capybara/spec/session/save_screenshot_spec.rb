# frozen_string_literal: true

Capybara::SpecHelper.spec '#save_screenshot', requires: [:screenshot] do
  let(:alternative_path) { File.join(Dir.pwd, 'save_screenshot_tmp') }
  before do
    @old_save_path = Capybara.save_path
    Capybara.save_path = nil
    @session.visit '/foo'
  end

  after do
    Capybara.save_path = @old_save_path
    FileUtils.rm_rf alternative_path
  end

  it 'generates sensible filename' do
    allow(@session.driver).to receive(:save_screenshot)

    @session.save_screenshot

    regexp = Regexp.new(File.join(Dir.pwd, 'capybara-\d+\.png'))
    expect(@session.driver).to have_received(:save_screenshot).with(regexp, any_args)
  end

  it 'allows to specify another path' do
    allow(@session.driver).to receive(:save_screenshot)

    custom_path = 'screenshots/1.png'
    @session.save_screenshot(custom_path)

    expect(@session.driver).to have_received(:save_screenshot).with(/#{custom_path}$/, any_args)
  end

  context 'with Capybara.save_path' do
    it 'file is generated in the correct location' do
      Capybara.save_path = alternative_path
      allow(@session.driver).to receive(:save_screenshot)

      @session.save_screenshot

      regexp = Regexp.new(File.join(alternative_path, 'capybara-\d+\.png'))
      expect(@session.driver).to have_received(:save_screenshot).with(regexp, any_args)
    end

    it 'relative paths are relative to save_path' do
      Capybara.save_path = alternative_path
      allow(@session.driver).to receive(:save_screenshot)

      custom_path = 'screenshots/2.png'
      @session.save_screenshot(custom_path)

      expect(@session.driver).to have_received(:save_screenshot).with(File.expand_path(custom_path, alternative_path), any_args)
    end
  end
end
