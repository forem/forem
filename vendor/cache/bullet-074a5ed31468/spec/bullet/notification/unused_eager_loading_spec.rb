# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Notification
    describe UnusedEagerLoading do
      subject { UnusedEagerLoading.new([''], Post, %i[comments votes], 'path') }

      it do
        expect(subject.body).to eq(
          "  Post => [:comments, :votes]\n  Remove from your query: .includes([:comments, :votes])"
        )
      end
      it { expect(subject.title).to eq('AVOID eager loading in path') }
    end
  end
end
