# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AmazingPrint ActionView extensions',
               skip: -> { !ExtVerifier.has_rails? || ActiveRecord::VERSION::STRING >= '6.1' }.call do
  before do
    @view = ActionView::Base.new
  end

  it "uses HTML and adds 'debug_dump' class to plain <pre> tag" do
    markup = rand
    expect(@view.ap(markup, plain: true)).to eq(%(<pre class="debug_dump">#{markup}</pre>))
  end

  it "uses HTML and adds 'debug_dump' class to colorized <pre> tag" do
    markup = ' &<hello>'
    expect(@view.ap(markup)).to eq('<pre class="debug_dump"><kbd style="color:brown">&quot; &amp;&lt;hello&gt;&quot;</kbd></pre>')
  end

  it 'uses HTML and does set output to HTML safe' do
    expect(@view.ap('<p>Hello World</p>')).to be_html_safe
  end
end
