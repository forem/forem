# Records ingestion decisions, including suppressed impressions and feed visits.
# Keeping these separate avoids counting delivery retries as new impressions.
class FeedEventReceipt < ApplicationRecord
end
