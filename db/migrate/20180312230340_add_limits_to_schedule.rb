class AddLimitsToSchedule < ActiveRecord::Migration[4.2]
  def change
    add_column :schedules, :earliest, :datetime
    add_column :schedules, :latest, :datetime
  end
end
