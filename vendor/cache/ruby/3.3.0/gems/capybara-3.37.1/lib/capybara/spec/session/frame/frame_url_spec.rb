# frozen_string_literal: true

Capybara::SpecHelper.spec '#frame_url', requires: [:frames] do
  before do
    @session.visit('/within_frames')
  end

  it 'should return the url in a frame' do
    @session.within_frame('frameOne') do
      expect(@session.driver.frame_url).to end_with '/frame_one'
    end
  end

  it 'should return the url in FrameTwo' do
    @session.within_frame('frameTwo') do
      expect(@session.driver.frame_url).to end_with '/frame_two'
    end
  end

  it 'should return the url in the main frame' do
    expect(@session.driver.frame_url).to end_with('/within_frames')
  end
end
