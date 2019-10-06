# frozen_string_literal: true

require "rails_helper"

describe ChatChannels::IndexingJob, type: :job do
  include_examples "#enqueues_job", "chat_channels_indexing", chat_channel_id: 1
end
