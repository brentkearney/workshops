class AddSyncTimeToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :sync_time, :datetime
  end
end
