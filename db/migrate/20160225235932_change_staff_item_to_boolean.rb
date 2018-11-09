class ChangeStaffItemToBoolean < ActiveRecord::Migration[4.2]
  def change
    change_column :schedules, :staff_item, 'boolean USING CAST(staff_item AS boolean)', null: false, default: false
  end
end
