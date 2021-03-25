require "spec_helper"

describe Buffer::Encode do

  context "successful code" do

  let(:schedule_first) { { :days => ["mon", "tue", "wed", "thu"], :times => ["12:00", "13:00"]} }
  let(:schedule_second) { { :days => ["sun", "sat"], :times => ["09:00", "24:00"]} }
  let(:schedules_hash) { { schedules: [schedule_first, schedule_second] } }
  let(:short_schedule) { { days: ["mon", "tue", "wed"], times: ["12:00", "17:00", "18:00"]} }
  let(:short_schedule_encoded) { "[days][]=mon&[days][]=tue&[times][]=12%3A00&[times][]=13%3A00" }
  let(:schedules_encoded) { "schedules[0][days][]=mon&schedules[0][days][]=tue&schedules[0][days][]=wed&schedules[0][times][]=12:00&schedules[0][times][]=17:00&schedules[0][times][]=18:00" }
  let(:very_short_schedule) { { :days => ["sun", "sat"], :times => ["09:00", "24:00"]} }


  describe "#encode"
    it "converts to match Buffer API specs encoding" do
      Buffer::Encode.encode([short_schedule]).
        should eq(schedules_encoded.gsub(/:/, '%3A'))
    end

    it "processes an input array of schedules" do
      Buffer::Encode.encode([very_short_schedule, very_short_schedule]).
        should eq("schedules[0][days][]=sun&schedules[0][days][]=sat&schedules[0][times][]=09%3A00&schedules[0][times][]=24%3A00&schedules[1][days][]=sun&schedules[1][days][]=sat&schedules[1][times][]=09%3A00&schedules[1][times][]=24%3A00")
    end

    it "includes index in conversion when multiple schedules present" do
      Buffer::Encode.encode([very_short_schedule, very_short_schedule, very_short_schedule]).
        should eq("schedules[0][days][]=sun&schedules[0][days][]=sat&schedules[0][times][]=09%3A00&schedules[0][times][]=24%3A00&schedules[1][days][]=sun&schedules[1][days][]=sat&schedules[1][times][]=09%3A00&schedules[1][times][]=24%3A00&schedules[2][days][]=sun&schedules[2][days][]=sat&schedules[2][times][]=09%3A00&schedules[2][times][]=24%3A00")
    end

    it "processes an input hash" do
      Buffer::Encode.encode({ schedules: [very_short_schedule, very_short_schedule, very_short_schedule] }).
        should eq("schedules[0][days][]=sun&schedules[0][days][]=sat&schedules[0][times][]=09%3A00&schedules[0][times][]=24%3A00&schedules[1][days][]=sun&schedules[1][days][]=sat&schedules[1][times][]=09%3A00&schedules[1][times][]=24%3A00&schedules[2][days][]=sun&schedules[2][days][]=sat&schedules[2][times][]=09%3A00&schedules[2][times][]=24%3A00")
    end
  end

  describe "#encode_schedule_primary" do
  end


end
