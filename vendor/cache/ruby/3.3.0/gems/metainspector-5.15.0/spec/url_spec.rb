require 'spec_helper'

describe MetaInspector::URL do
  it "should normalize URLs" do
    expect(MetaInspector::URL.new('http://example.com').url).to eq('http://example.com/')
  end

  it 'should accept an URL with a scheme' do
    expect(MetaInspector::URL.new('http://example.com/').url).to eq('http://example.com/')
  end

  it "should use http:// as a default scheme" do
    expect(MetaInspector::URL.new('example.com').url).to eq('http://example.com/')
  end

  it "should accept an URL with international characters" do
    expect(MetaInspector::URL.new('http://international.com/olé').url).to eq('http://international.com/ol%C3%A9')
  end

  it "should return the scheme" do
    expect(MetaInspector::URL.new('http://example.com').scheme).to   eq('http')
    expect(MetaInspector::URL.new('https://example.com').scheme).to  eq('https')
    expect(MetaInspector::URL.new('example.com').scheme).to          eq('http')
  end

  it "should return the host" do
    expect(MetaInspector::URL.new('http://example.com').host).to   eq('example.com')
    expect(MetaInspector::URL.new('https://example.com').host).to  eq('example.com')
    expect(MetaInspector::URL.new('example.com').host).to          eq('example.com')
  end

  it "should return the root url" do
    expect(MetaInspector::URL.new('http://example.com').root_url).to        eq('http://example.com/')
    expect(MetaInspector::URL.new('https://example.com').root_url).to       eq('https://example.com/')
    expect(MetaInspector::URL.new('example.com').root_url).to               eq('http://example.com/')
    expect(MetaInspector::URL.new('http://example.com/faqs').root_url).to   eq('http://example.com/')
  end

  it "should return an untracked url" do
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_source=1234').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_medium=1234').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_term=1234').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_content=1234').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_campaign=1234').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_source=1234&utm_medium=5678&utm_term=4321&utm_content=9876&utm_campaign=5436').untracked_url).to eq('http://example.com/foo?not_utm_thing=bar')
    expect(MetaInspector::URL.new('http://example.com/foo?utm_source=1234&utm_medium=5678&utm_term=4321&utm_content=9876&utm_campaign=5436').untracked_url).to eq('http://example.com/foo')
    expect(MetaInspector::URL.new('http://example.com/foo').untracked_url).to eq('http://example.com/foo')
  end

  it "should remove tracking parameters from url" do

    tracked_urls = ['http://example.com/foo?not_utm_thing=bar&utm_source=1234',
                    'http://example.com/foo?not_utm_thing=bar&utm_medium=1234',
                    'http://example.com/foo?not_utm_thing=bar&utm_term=1234',
                    'http://example.com/foo?not_utm_thing=bar&utm_content=1234',
                    'http://example.com/foo?not_utm_thing=bar&utm_campaign=1234',
                    'http://example.com/foo?not_utm_thing=bar&utm_source=1234&utm_medium=5678&utm_term=4321&utm_content=9876&utm_campaign=5436'
    ]

    tracked_urls.each do |tracked_url|
      url = MetaInspector::URL.new(tracked_url)
      url.untrack!
      expect(url.url).to eq('http://example.com/foo?not_utm_thing=bar')
    end
  end

  it "should remove all query values when untrack url" do
    url = MetaInspector::URL.new('http://example.com/foo?utm_campaign=1234')
    url.untrack!
    expect(url.url).to eq('http://example.com/foo')
  end

  it "should untrack untracked url" do
    url = MetaInspector::URL.new('http://example.com/foo')
    url.untrack!
    expect(url.url).to eq('http://example.com/foo')
  end

  it "should say if the url is tracked" do
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_source=1234').tracked?).to be true
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_medium=1234').tracked?).to be true
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_term=1234').tracked?).to be true
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_content=1234').tracked?).to be true
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_campaign=1234').tracked?).to be true
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&utm_source=1234&utm_medium=5678&utm_term=4321&utm_content=9876&utm_campaign=5436').tracked?).to be true

    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&not_utm_source=1234').tracked?).to be false
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&not_utm_medium=1234').tracked?).to be false
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&not_utm_term=1234').tracked?).to be false
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&not_utm_content=1234').tracked?).to be false
    expect(MetaInspector::URL.new('http://example.com/foo?not_utm_thing=bar&not_utm_campaign=1234').tracked?).to be false

    expect(MetaInspector::URL.new('http://example.com/foo').tracked?).to be false
  end

  describe "url=" do
    it "should update the url" do
      url = MetaInspector::URL.new('http://first.com/')

      url.url         = 'http://second.com/'
      expect(url.url).to eq('http://second.com/')
    end

    it "should add the missing scheme and normalize" do
      url = MetaInspector::URL.new('http://first.com/')

      url.url         = 'second.com'
      expect(url.url).to eq('http://second.com/')
    end
  end

  describe "handling malformed URLs" do
    it "detects empty URLs" do
      expect do
        MetaInspector::URL.new('')
      end.to raise_error(MetaInspector::ParserError)
    end

    it "detects incomplete URLs" do
      expect do
        MetaInspector::URL.new('http:')
      end.to raise_error(MetaInspector::ParserError)
    end
  end
end
