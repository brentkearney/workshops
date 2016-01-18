class AddStaffItemToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :staff_item, :integer
  end
end
