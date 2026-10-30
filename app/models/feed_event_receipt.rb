# Records ingestion decisions, including impressions suppressed by the timebox.
# Keeping these separate avoids counting delivery retries as new impressions.
class FeedEventReceipt < ApplicationRecord
end
