class RemoveExistingSegmentedUsers < ActiveRecord::Migration[7.0]
  def up
    sql = <<-SQL
      DELETE FROM segmented_users deduped_seg_users
      USING segmented_users current_seg_users
      WHERE
        deduped_seg_users.id < current_seg_users.id AND
        deduped_seg_users.user_id = current_seg_users.user_id AND
        deduped_seg_users.audience_segment_id = current_seg_users.audience_segment_id;
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
