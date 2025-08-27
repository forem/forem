class SetPositionsForExistingPollsAndOptions < ActiveRecord::Migration[7.0]
  def up
    # Set positions for polls within each survey based on creation order
    Survey.find_each do |survey|
      survey.polls.order(:created_at).each_with_index do |poll, index|
        poll.update_column(:position, index)
      end
    end

    # Set positions for poll options within each poll based on creation order
    Poll.find_each do |poll|
      poll.poll_options.order(:created_at).each_with_index do |option, index|
        option.update_column(:position, index)
      end
    end
  end

  def down
    # No need to revert positions as they're just ordering
  end
end
