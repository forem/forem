# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Notification
    describe NPlusOneQuery do
      subject { NPlusOneQuery.new([%w[caller1 caller2]], Post, %i[comments votes], 'path') }

      it do
        expect(subject.body_with_caller).to eq(
          "  Post => [:comments, :votes]\n  Add to your query: .includes([:comments, :votes])\nCall stack\n  caller1\n  caller2\n"
        )
      end
      it do
        expect([subject.body_with_caller, subject.body_with_caller]).to eq(
          [
            "  Post => [:comments, :votes]\n  Add to your query: .includes([:comments, :votes])\nCall stack\n  caller1\n  caller2\n",
            "  Post => [:comments, :votes]\n  Add to your query: .includes([:comments, :votes])\nCall stack\n  caller1\n  caller2\n"
          ]
        )
      end
      it do
        expect(subject.body).to eq("  Post => [:comments, :votes]\n  Add to your query: .includes([:comments, :votes])")
      end
      it { expect(subject.title).to eq('USE eager loading in path') }
    end
  end
end
