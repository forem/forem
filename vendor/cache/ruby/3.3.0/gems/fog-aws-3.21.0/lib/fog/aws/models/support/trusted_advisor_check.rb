module Fog
  module AWS
    class Support
      class TrustedAdvisorCheck < Fog::Model
        identity :id, :aliases => 'checkId'

        attribute :name
        attribute :category
        attribute :description
        attribute :metadata
        attribute :flagged_resources,         :aliases => 'flaggedResources'
        attribute :resources_summary,         :aliases => 'resourcesSummary'
        attribute :status
        attribute :timestamp
        attribute :category_specific_summary, :aliases => 'categorySpecificSummary'

        def populate_extended_attributes(lazy=false)
          return if lazy == true
          data = service.describe_trusted_advisor_check_result(:id => self.identity).body["result"]
          merge_attributes(data)
        end

        def flagged_resources(lazy=true)
          if attributes[:flagged_resources].nil?
            populate_extended_attributes(lazy)

            if attributes[:flagged_resources]
              map_flagged_resources!
              service.flagged_resources.load(attributes[:flagged_resources])
            else
              nil
            end
          else
            if attributes[:flagged_resources].first['metadata'].is_a?(Array)
              map_flagged_resources!
            end
            service.flagged_resources.load(attributes[:flagged_resources])
          end
        end

        def category_specific_summary(lazy=true)
          populate_extended_attributes(lazy) if attributes[:category_specific_summary].nil?
          attributes[:category_stecific_summary]
        end

        def resources_summary(lazy=true)
          populate_extended_attributes(lazy) if attributes[:resources_summary].nil?
          attributes[:resources_summary]
        end

        private

        def map_flagged_resources!
          attributes[:flagged_resources].map! do |fr|
            fr['metadata'] = fr['metadata'].each_with_index.inject({}) do |hash,(data,index)|
              hash[self.metadata[index]] = data
              hash
            end
            fr
          end
        end
      end
    end
  end
end
