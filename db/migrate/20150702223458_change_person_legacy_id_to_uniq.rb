class ChangePersonLegacyIdToUniq < ActiveRecord::Migration
  def change
    change_column :people, :legacy_id, :integer, unique: true
  end
end
