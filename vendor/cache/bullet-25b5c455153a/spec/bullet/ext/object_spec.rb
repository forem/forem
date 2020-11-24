# frozen_string_literal: true

require 'spec_helper'

describe Object do
  context 'bullet_key' do
    it 'should return class and id composition' do
      post = Post.first
      expect(post.bullet_key).to eq("Post:#{post.id}")
    end

    if mongoid?
      it 'should return class with namesapce and id composition' do
        post = Mongoid::Post.first
        expect(post.bullet_key).to eq("Mongoid::Post:#{post.id}")
      end
    end
  end

  context 'bullet_primary_key_value' do
    it 'should return id' do
      post = Post.first
      expect(post.bullet_primary_key_value).to eq(post.id)
    end

    it 'should return primary key value' do
      post = Post.first
      Post.primary_key = 'name'
      expect(post.bullet_primary_key_value).to eq(post.name)
      Post.primary_key = 'id'
    end

    it 'should return value for multiple primary keys' do
      post = Post.first
      allow(Post).to receive(:primary_keys).and_return(%i[category_id writer_id])
      expect(post.bullet_primary_key_value).to eq("#{post.category_id},#{post.writer_id}")
    end

    it 'it should return nil for unpersisted records' do
      post = Post.new(id: 123)
      expect(post.bullet_primary_key_value).to be_nil
    end
  end
end
