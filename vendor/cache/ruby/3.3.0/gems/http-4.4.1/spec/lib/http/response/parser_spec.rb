# frozen_string_literal: true

RSpec.describe HTTP::Response::Parser do
  subject(:parser) { described_class.new }
  let(:raw_response) do
    "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nContent-Type: application/json\r\nMy-Header: val\r\nEmpty-Header: \r\n\r\n{}"
  end
  let(:expected_headers) do
    {
      "Content-Length" => "2",
      "Content-Type"   => "application/json",
      "My-Header"      => "val",
      "Empty-Header"   => ""
    }
  end
  let(:expected_body) { "{}" }

  before do
    parts.each { |part| subject.add(part) }
  end

  context "whole response in one part" do
    let(:parts) { [raw_response] }

    it "parses headers" do
      expect(subject.headers.to_h).to eq(expected_headers)
    end

    it "parses body" do
      expect(subject.read(expected_body.size)).to eq(expected_body)
    end
  end

  context "response in many parts" do
    let(:parts) { raw_response.split(//) }

    it "parses headers" do
      expect(subject.headers.to_h).to eq(expected_headers)
    end

    it "parses body" do
      expect(subject.read(expected_body.size)).to eq(expected_body)
    end
  end
end
