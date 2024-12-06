# frozen_string_literal: true

module Feedjira
  module Parser
    class GoogleDocsAtomEntry
      include SAXMachine
      include FeedEntryUtilities
      include AtomEntryUtilities

      element :"docs:md5Checksum", as: :checksum
      element :"docs:filename", as: :original_filename
      element :"docs:suggestedFilename", as: :suggested_filename
    end
  end
end
