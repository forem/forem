# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::PodloveChapter do
  before do
    @item = Feedjira::Parser::ITunesRSS.parse(sample_podlove_feed).entries.first
    @chapter = @item.chapters.first
  end

  it "parses chapters" do
    expect(@item.chapters.size).to eq 15
  end

  it "sorts chapters by time" do
    expect(@item.chapters.last.title).to eq "Abschied"
  end

  it "parses the start time" do
    expect(@chapter.start_ntp).to eq "00:00:26.407"
    expect(@chapter.start).to eq 26.407
    expect(@item.chapters[1].start).to eq 50
    expect(@item.chapters[2].start).to eq 59.12
    expect(@item.chapters[3].start).to eq 89.201
    expect(@item.chapters.last.start).to eq 5700.034
  end

  it "parses the title" do
    expect(@chapter.title).to eq "Neil DeGrasse Tyson on Science"
  end

  it "parses the link" do
    expect(@chapter.url).to eq "https://example.com"
  end

  it "parses the image" do
    expect(@chapter.image).to eq "https://pics.example.com/pic.png"
  end
end
