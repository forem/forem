# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache::CacheControl do
  it 'takes a String with multiple name=value pairs' do
    cache_control = Faraday::HttpCache::CacheControl.new('max-age=600, max-stale=300, min-fresh=570')
    expect(cache_control.max_age).to eq(600)
  end

  it 'takes a String with a single flag value' do
    cache_control = Faraday::HttpCache::CacheControl.new('no-cache')
    expect(cache_control).to be_no_cache
  end

  it 'takes a String with a bunch of all kinds of stuff' do
    cache_control =
      Faraday::HttpCache::CacheControl.new('max-age=600,must-revalidate,min-fresh=3000,foo=bar,baz')
    expect(cache_control.max_age).to eq(600)
    expect(cache_control).to be_must_revalidate
  end

  it 'strips leading and trailing spaces' do
    cache_control = Faraday::HttpCache::CacheControl.new('   public,   max-age =   600  ')
    expect(cache_control).to be_public
    expect(cache_control.max_age).to eq(600)
  end

  it 'ignores blank segments' do
    cache_control = Faraday::HttpCache::CacheControl.new('max-age=600,,s-maxage=300')
    expect(cache_control.max_age).to eq(600)
    expect(cache_control.shared_max_age).to eq(300)
  end

  it 'sorts alphabetically with boolean directives before value directives' do
    cache_control = Faraday::HttpCache::CacheControl.new('foo=bar, z, x, y, bling=baz, zoom=zib, b, a')
    expect(cache_control.to_s).to eq('a, b, x, y, z, bling=baz, foo=bar, zoom=zib')
  end

  it 'responds to #max_age with an integer when max-age directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public, max-age=600')
    expect(cache_control.max_age).to eq(600)
  end

  it 'responds to #max_age with nil when no max-age directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public')
    expect(cache_control.max_age).to be_nil
  end

  it 'responds to #shared_max_age with an integer when s-maxage directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public, s-maxage=600')
    expect(cache_control.shared_max_age).to eq(600)
  end

  it 'responds to #shared_max_age with nil when no s-maxage directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public')
    expect(cache_control.shared_max_age).to be_nil
  end

  it 'responds to #public? truthfully when public directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public')
    expect(cache_control).to be_public
  end

  it 'responds to #public? non-truthfully when no public directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('private')
    expect(cache_control).not_to be_public
  end

  it 'responds to #private? truthfully when private directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('private')
    expect(cache_control).to be_private
  end

  it 'responds to #private? non-truthfully when no private directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('public')
    expect(cache_control).not_to be_private
  end

  it 'responds to #no_cache? truthfully when no-cache directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('no-cache')
    expect(cache_control).to be_no_cache
  end

  it 'responds to #no_cache? non-truthfully when no no-cache directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('max-age=600')
    expect(cache_control).not_to be_no_cache
  end

  it 'responds to #must_revalidate? truthfully when must-revalidate directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('must-revalidate')
    expect(cache_control).to be_must_revalidate
  end

  it 'responds to #must_revalidate? non-truthfully when no must-revalidate directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('max-age=600')
    expect(cache_control).not_to be_must_revalidate
  end

  it 'responds to #proxy_revalidate? truthfully when proxy-revalidate directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('proxy-revalidate')
    expect(cache_control).to be_proxy_revalidate
  end

  it 'responds to #proxy_revalidate? non-truthfully when no proxy-revalidate directive present' do
    cache_control = Faraday::HttpCache::CacheControl.new('max-age=600')
    expect(cache_control).not_to be_no_cache
  end
end
