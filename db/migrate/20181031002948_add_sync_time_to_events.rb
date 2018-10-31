class AddSyncTimeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :sync_time, :datetime
  end
end
