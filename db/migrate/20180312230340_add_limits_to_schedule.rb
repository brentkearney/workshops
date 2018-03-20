class AddLimitsToSchedule < ActiveRecord::Migration
  def change
    add_column :schedules, :earliest, :datetime
    add_column :schedules, :latest, :datetime
  end
end
