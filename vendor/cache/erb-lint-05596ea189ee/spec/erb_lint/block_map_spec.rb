# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Utils::BlockMap do
  include ::AST::Sexp

  describe 'map' do
    let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
    let(:block_map) { described_class.new(processed_source) }
    subject { block_map.connections }

    context 'with block' do
      let(:file) { <<~ERB }
        <%= javascript_tag do %>
          foo
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:block))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<%= javascript_tag do %>", "<% end %>"]))
      end
    end

    context 'with block in single erb tag' do
      let(:file) { <<~ERB }
        <%= javascript_tag do foo; end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:block))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<%= javascript_tag do foo; end %>"]))
      end
    end

    context 'with if' do
      let(:file) { <<~ERB }
        <% if foo %>
          foo
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:if))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<% if foo %>", "<% end %>"]))
      end
    end

    context 'with if..else' do
      let(:file) { <<~ERB }
        <% if foo %>
          a
        <% else %>
          b
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:if))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<% if foo %>", "<% else %>", "<% end %>"]))
      end
    end

    context 'with if..elsif..end' do
      let(:file) { <<~ERB }
        <% if foo %>
          a
        <% elsif bar %>
          b
        <% elsif baz %>
          c
        <% elsif qux %>
          d
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:if))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq([
          "<% if foo %>",
          "<% elsif bar %>",
          "<% elsif baz %>",
          "<% elsif qux %>",
          "<% end %>",
        ]))
      end
    end

    context 'with block and if' do
      let(:file) { <<~ERB }
        <% foo do %>
          <% if bar %>
            baz
          <% end %>
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(2))
        expect(subject[0].type).to(eq(:block))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<% foo do %>", "<% end %>"]))
        expect(subject[0].nodes.map(&:loc).map(&:range)).to(eq([0...12, 48...57]))
        expect(subject[1].type).to(eq(:if))
        expect(subject[1].nodes.map(&:loc).map(&:source)).to(eq(["<% if bar %>", "<% end %>"]))
        expect(subject[1].nodes.map(&:loc).map(&:range)).to(eq([15...27, 38...47]))
      end
    end

    context 'with block and if overlapping' do
      let(:file) { <<~ERB }
        <% foo do
          if bar %>
            baz
          <% end %>
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:block))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<% foo do\n  if bar %>", "<% end %>", "<% end %>"]))
        expect(subject[0].nodes.map(&:loc).map(&:range)).to(eq([0...21, 32...41, 42...51]))
      end
    end

    context 'with begin..end' do
      let(:file) { <<~ERB }
        <% begin %>
          foo
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:begin))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq(["<% begin %>", "<% end %>"]))
      end
    end

    context 'with begin..rescue..end' do
      let(:file) { <<~ERB }
        <% begin %>
          <%= bla rescue nil %>
        <% rescue Error1 => e %>
          bar
        <% rescue Error2 => e %>
          bar
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:begin))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq([
          "<% begin %>",
          "<% rescue Error1 => e %>",
          "<% rescue Error2 => e %>",
          "<% end %>",
        ]))
      end
    end

    context 'with case' do
      let(:file) { <<~ERB }
        <% case foo %>
        <% when :bar %>
          bar
        <% when :baz %>
          <%= bla rescue nil %>
        <% else %>
          baz
        <% end %>
      ERB

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].type).to(eq(:case))
        expect(subject[0].nodes.map(&:loc).map(&:source)).to(eq([
          "<% case foo %>",
          "<% when :bar %>",
          "<% when :baz %>",
          "<% else %>",
          "<% end %>",
        ]))
      end
    end
  end
end
