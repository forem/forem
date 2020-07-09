class AddUniqueIndexToProfilePinsPinnableId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :profile_pins,
      %i[pinnable_id profile_id profile_type pinnable_type],
      unique: true,
      algorithm: :concurrently,
      # needs a custom name as the generated one is too long
      name: :idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type
    )
  end
end
