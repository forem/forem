rspec-expectations is used to define expected outcomes.

    RSpec.describe Account do
      it "has a balance of zero when first created" do
        expect(Account.new.balance).to eq(Money.new(0))
      end
    end

## Basic structure

The basic structure of an rspec expectation is:

    expect(actual).to matcher(expected)
    expect(actual).not_to matcher(expected)

Note: You can also use `expect(..).to_not` instead of `expect(..).not_to`.
      One is an alias to the other, so you can use whichever reads better to you.

#### Examples

    expect(5).to eq(5)
    expect(5).not_to eq(4)

## What is a matcher?

A matcher is any object that responds to the following methods:

    matches?(actual)
    failure_message

These methods are also part of the matcher protocol, but are optional:

    does_not_match?(actual)
    failure_message_when_negated
    description
    supports_block_expectations?

RSpec ships with a number of built-in matchers and a DSL for writing custom
matchers.

## Issues

The documentation for rspec-expectations is a work in progress. We'll be adding
Cucumber features over time, and clarifying existing ones.  If you have
specific features you'd like to see added, find the existing documentation
incomplete or confusing, or, better yet, wish to write a missing Cucumber
feature yourself, please [submit an
issue](http://github.com/rspec/rspec-expectations/issues) or a [pull
request](http://github.com/rspec/rspec-expectations).
