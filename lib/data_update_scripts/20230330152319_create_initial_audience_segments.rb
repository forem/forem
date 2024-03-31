module DataUpdateScripts
  class CreateInitialAudienceSegments
    def run
      AudienceSegment::QUERIES.each_key do |segment_type|
        AudienceSegment.find_or_create_by type_of: segment_type
      end
    end
  end
end
