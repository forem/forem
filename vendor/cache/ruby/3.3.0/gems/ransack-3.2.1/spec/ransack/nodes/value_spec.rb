require 'spec_helper'

module Ransack
  module Nodes
    describe Value do
      let(:context) { Context.for(Person) }

      subject do
        Value.new(context, raw_value)
      end

      context "with a date value" do
        let(:raw_value) { "2022-05-23" }

        [:date].each do |type|
          it "should cast #{type} correctly" do
            result = subject.cast(type)

            expect(result).to be_a_kind_of(Date)
            expect(result).to eq(Date.parse(raw_value))
          end
        end
      end

      context "with a timestamp value" do
        let(:raw_value) { "2022-05-23 10:40:02 -0400" }

        [:datetime, :timestamp, :time, :timestamptz].each do |type|
          it "should cast #{type} correctly" do
            result = subject.cast(type)

            expect(result).to be_a_kind_of(Time)
            expect(result).to eq(Time.zone.parse(raw_value))
          end
        end
      end

      Constants::TRUE_VALUES.each do |value|
        context "with a true boolean value (#{value})" do
          let(:raw_value) { value.to_s }

          it "should cast boolean correctly" do
            result = subject.cast(:boolean)
            expect(result).to eq(true)
          end
        end
      end

      Constants::FALSE_VALUES.each do |value|
        context "with a false boolean value (#{value})" do
          let(:raw_value) { value.to_s }

          it "should cast boolean correctly" do
            result = subject.cast(:boolean)

            expect(result).to eq(false)
          end
        end
      end

      ["12", "101.5"].each do |value|
        context "with an integer value (#{value})" do
          let(:raw_value) { value }

          it "should cast #{value} to integer correctly" do
            result = subject.cast(:integer)

            expect(result).to be_an(Integer)
            expect(result).to eq(value.to_i)
          end
        end
      end

      ["12", "101.5"].each do |value|
        context "with a float value (#{value})" do
          let(:raw_value) { value }

          it "should cast #{value} to float correctly" do
            result = subject.cast(:float)

            expect(result).to be_an(Float)
            expect(result).to eq(value.to_f)
          end
        end
      end

      ["12", "101.5"].each do |value|
        context "with a decimal value (#{value})" do
          let(:raw_value) { value }

          it "should cast #{value} to decimal correctly" do
            result = subject.cast(:decimal)

            expect(result).to be_a(BigDecimal)
            expect(result).to eq(value.to_d)
          end
        end
      end

      ["12", "101.513"].each do |value|
        context "with a money value (#{value})" do
          let(:raw_value) { value }

          it "should cast #{value} to money correctly" do
            result = subject.cast(:money)

            expect(result).to be_a(String)
            expect(result).to eq(value.to_f.to_s)
          end
        end
      end

    end
  end
end
