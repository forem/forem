# frozen_string_literal: true

require 'spec_helper'

if !mongoid? && active_record?
  describe Bullet::Detector::CounterCache do
    before(:each) { Bullet.start_request }

    after(:each) { Bullet.end_request }

    it 'should need counter cache with all cities' do
      Country.all.each { |country| country.cities.size }
      expect(Bullet.collected_counter_cache_notifications).not_to be_empty
    end

    it 'should not need counter cache if already define counter_cache' do
      Person.all.each { |person| person.pets.size }
      expect(Bullet.collected_counter_cache_notifications).to be_empty
    end

    it 'should not need counter cache with only one object' do
      Country.first.cities.size
      expect(Bullet.collected_counter_cache_notifications).to be_empty
    end

    it 'should not need counter cache without size' do
      Country.includes(:cities).each { |country| country.cities.empty? }
      expect(Bullet.collected_counter_cache_notifications).to be_empty
    end

    if active_record5? || active_record6?
      it 'should not need counter cache for has_many through' do
        Client.all.each { |client| client.firms.size }
        expect(Bullet.collected_counter_cache_notifications).to be_empty
      end
    else
      it 'should need counter cache for has_many through' do
        Client.all.each { |client| client.firms.size }
        expect(Bullet.collected_counter_cache_notifications).not_to be_empty
      end
    end

    it 'should not need counter cache with part of cities' do
      Country.all.each { |country| country.cities.where(name: 'first').size }
      expect(Bullet.collected_counter_cache_notifications).to be_empty
    end

    context 'disable' do
      before { Bullet.counter_cache_enable = false }
      after { Bullet.counter_cache_enable = true }

      it 'should not detect counter cache' do
        Country.all.each { |country| country.cities.size }
        expect(Bullet.collected_counter_cache_notifications).to be_empty
      end
    end

    context 'whitelist' do
      before { Bullet.add_whitelist type: :counter_cache, class_name: 'Country', association: :cities }
      after { Bullet.clear_whitelist }

      it 'should not detect counter cache' do
        Country.all.each { |country| country.cities.size }
        expect(Bullet.collected_counter_cache_notifications).to be_empty
      end
    end
  end
end
