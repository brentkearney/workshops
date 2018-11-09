class AddStaffItemToSchedules < ActiveRecord::Migration[4.2]
  def change
    add_column :schedules, :staff_item, :integer
  end
end
