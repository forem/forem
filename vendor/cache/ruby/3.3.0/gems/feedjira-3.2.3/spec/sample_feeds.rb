# frozen_string_literal: true

module SampleFeeds
  FEEDS = {
    sample_atom_feed: "AmazonWebServicesBlog.xml",
    sample_atom_simple: "atom_simple_single_entry.xml",
    sample_atom_simple_link_self: "atom_simple_single_entry_link_self.xml",
    sample_atom_middleman_feed: "FeedjiraBlog.xml",
    sample_atom_xhtml_feed: "pet_atom.xml",
    sample_atom_feed_line_breaks: "AtomFeedWithSpacesAroundEquals.xml",
    sample_atom_entry_content: "AmazonWebServicesBlogFirstEntryContent.xml",
    sample_itunes_feed: "itunes.xml",
    sample_itunes_feedburner_feed: "itunes_feedburner.xml",
    sample_itunes_feed_with_single_quotes: "ITunesWithSingleQuotedAttributes.xml",
    sample_itunes_feed_with_spaces: "ITunesWithSpacesInAttributes.xml",
    sample_podlove_feed: "CRE.xml",
    sample_rdf_feed: "HREFConsideredHarmful.xml",
    sample_rdf_entry_content: "HREFConsideredHarmfulFirstEntry.xml",
    sample_rss_feed_burner_feed: "TechCrunch.xml",
    sample_rss_feed_burner_entry_content: "TechCrunchFirstEntry.xml",
    sample_rss_feed_burner_entry_description: "TechCrunchFirstEntryDescription.xml",
    sample_rss_feed: "TenderLovemaking.xml",
    sample_rss_entry_content: "TenderLovemakingFirstEntry.xml",
    sample_feedburner_atom_feed: "PaulDixExplainsNothing.xml",
    sample_feedburner_atom_feed_alternate: "GiantRobotsSmashingIntoOtherGiantRobots.xml",
    sample_feedburner_atom_entry_content: "PaulDixExplainsNothingFirstEntryContent.xml",
    sample_google_alerts_atom_feed: "google_alerts_atom.xml",
    sample_wfw_feed: "PaulDixExplainsNothingWFW.xml",
    sample_google_docs_list_feed: "GoogleDocsList.xml",
    sample_feed_burner_atom_xhtml_feed: "FeedBurnerXHTML.xml",
    sample_duplicate_content_atom_feed: "DuplicateContentAtomFeed.xml",
    sample_youtube_atom_feed: "youtube_atom.xml",
    sample_atom_xhtml_with_escpaed_html_in_pre_tag_feed: "AtomEscapedHTMLInPreTag.xml",
    sample_json_feed: "json_feed.json",
    sample_rss_feed_huffpost_ca: "HuffPostCanada.xml",
    sample_invalid_date_format_feed: "InvalidDateFormat.xml",
    sample_rss_feed_permalinks: "Permalinks.xml",
    sample_rss_feed_with_a10_namespace: "a10.xml",
    sample_rss_feed_with_comments: "RSSWithComments.xml"
  }.freeze

  FEEDS.each do |method, filename|
    define_method(method) { load_sample filename }
  end

  def load_sample(filename)
    File.read("#{File.dirname(__FILE__)}/sample_feeds/#{filename}")
  end
end
