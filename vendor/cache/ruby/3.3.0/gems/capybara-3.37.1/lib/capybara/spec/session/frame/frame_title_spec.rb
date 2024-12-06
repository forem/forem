# frozen_string_literal: true

Capybara::SpecHelper.spec '#frame_title', requires: [:frames] do
  before do
    @session.visit('/within_frames')
  end

  it 'should return the title in a frame' do
    @session.within_frame('frameOne') do
      expect(@session.driver.frame_title).to eq 'This is the title of frame one'
    end
  end

  it 'should return the title in FrameTwo' do
    @session.within_frame('frameTwo') do
      expect(@session.driver.frame_title).to eq 'This is the title of frame two'
    end
  end

  it 'should return the title in the main frame' do
    expect(@session.driver.frame_title).to eq 'With Frames'
  end
end
