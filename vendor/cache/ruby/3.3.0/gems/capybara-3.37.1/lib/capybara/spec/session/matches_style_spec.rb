# frozen_string_literal: true

Capybara::SpecHelper.spec '#matches_style?', requires: [:css] do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the element has the given style' do
    expect(@session.find(:css, '#first')).to match_style(display: 'block')
    expect(@session.find(:css, '#first').matches_style?(display: 'block')).to be true
    expect(@session.find(:css, '#second')).to match_style('display' => 'inline')
    expect(@session.find(:css, '#second').matches_style?('display' => 'inline')).to be true
  end

  it 'should be false if the element does not have the given style' do
    expect(@session.find(:css, '#first').matches_style?('display' => 'inline')).to be false
    expect(@session.find(:css, '#second').matches_style?(display: 'block')).to be false
  end

  it 'allows Regexp for value matching' do
    expect(@session.find(:css, '#first')).to match_style(display: /^bl/)
    expect(@session.find(:css, '#first').matches_style?('display' => /^bl/)).to be true
    expect(@session.find(:css, '#first').matches_style?(display: /^in/)).to be false
  end

  it 'deprecated has_style?' do
    expect { have_style(display: /^bl/) }.to \
      output(/have_style is deprecated/).to_stderr

    el = @session.find(:css, '#first')
    allow(Capybara::Helpers).to receive(:warn).and_return(nil)
    el.has_style?('display' => /^bl/)
    expect(Capybara::Helpers).to have_received(:warn)
  end
end
