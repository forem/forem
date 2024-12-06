# frozen_string_literal: true

Capybara::SpecHelper.spec '#switch_to_frame', requires: [:frames] do
  before do
    @session.visit('/within_frames')
  end

  after do
    # Ensure we clean up after the frame changes
    @session.switch_to_frame(:top)
  end

  it 'should find the div in frameOne' do
    frame = @session.find(:frame, 'frameOne')
    @session.switch_to_frame(frame)
    expect(@session.find("//*[@id='divInFrameOne']").text).to eql 'This is the text of divInFrameOne'
  end

  it 'should find the div in FrameTwo' do
    frame = @session.find(:frame, 'frameTwo')
    @session.switch_to_frame(frame)
    expect(@session.find("//*[@id='divInFrameTwo']").text).to eql 'This is the text of divInFrameTwo'
  end

  it 'should return to the parent frame when told to' do
    frame = @session.find(:frame, 'frameOne')
    @session.switch_to_frame(frame)
    @session.switch_to_frame(:parent)
    expect(@session.find("//*[@id='divInMainWindow']").text).to eql 'This is the text for divInMainWindow'
  end

  it 'should be able to switch to nested frames' do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame frame
    frame = @session.find(:frame, 'childFrame')
    @session.switch_to_frame frame
    frame = @session.find(:frame, 'grandchildFrame1')
    @session.switch_to_frame frame
    expect(@session).to have_selector(:css, '#divInFrameOne', text: 'This is the text of divInFrameOne')
  end

  it 'should reset scope when changing frames' do
    frame = @session.find(:frame, 'parentFrame')
    @session.within(:css, '#divInMainWindow') do
      @session.switch_to_frame(frame)
      expect(@session.has_selector?(:css, 'iframe#childFrame')).to be true
      @session.switch_to_frame(:parent)
    end
  end

  it 'works if the frame is closed', requires: %i[frames js] do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame frame
    frame = @session.find(:frame, 'childFrame')
    @session.switch_to_frame frame
    @session.click_link 'Close Window Now'
    @session.switch_to_frame :parent # Go back to parentFrame
    expect(@session).to have_selector(:css, 'body#parentBody')
    expect(@session).not_to have_selector(:css, '#childFrame')
    @session.switch_to_frame :parent # Go back to top
  end

  it 'works if the frame is closed with a slight delay', requires: %i[frames js] do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame frame
    frame = @session.find(:frame, 'childFrame')
    @session.switch_to_frame frame
    @session.click_link 'Close Window Soon'
    sleep 1
    @session.switch_to_frame :parent # Go back to parentFrame
    expect(@session).to have_selector(:css, 'body#parentBody')
    expect(@session).not_to have_selector(:css, '#childFrame')
    @session.switch_to_frame :parent # Go back to top
  end

  it 'can return to the top frame', requires: [:frames] do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame frame
    frame = @session.find(:frame, 'childFrame')
    @session.switch_to_frame frame
    @session.switch_to_frame :top
    expect(@session.find("//*[@id='divInMainWindow']").text).to eql 'This is the text for divInMainWindow'
  end

  it "should raise error if switching to parent unmatched inside `within` as it's nonsense" do
    expect do
      frame = @session.find(:frame, 'parentFrame')
      @session.switch_to_frame(frame)
      @session.within(:css, '#parentBody') do
        @session.switch_to_frame(:parent)
      end
    end.to raise_error(Capybara::ScopeError, "`switch_to_frame(:parent)` cannot be called from inside a descendant frame's `within` block.")
  end

  it "should raise error if switching to top inside a `within` in a frame as it's nonsense" do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame(frame)
    @session.within(:css, '#parentBody') do
      expect do
        @session.switch_to_frame(:top)
      end.to raise_error(Capybara::ScopeError, "`switch_to_frame(:top)` cannot be called from inside a descendant frame's `within` block.")
    end
  end

  it "should raise error if switching to top inside a nested `within` in a frame as it's nonsense" do
    frame = @session.find(:frame, 'parentFrame')
    @session.switch_to_frame(frame)
    @session.within(:css, '#parentBody') do
      @session.switch_to_frame(@session.find(:frame, 'childFrame'))
      expect do
        @session.switch_to_frame(:top)
      end.to raise_error(Capybara::ScopeError, "`switch_to_frame(:top)` cannot be called from inside a descendant frame's `within` block.")
      @session.switch_to_frame(:parent)
    end
  end
end
