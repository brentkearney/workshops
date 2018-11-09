class ChangePersonLegacyIdToUniq < ActiveRecord::Migration[4.2]
  def change
    change_column :people, :legacy_id, :integer, unique: true
  end
end
