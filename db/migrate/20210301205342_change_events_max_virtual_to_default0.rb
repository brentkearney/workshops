class ChangeEventsMaxVirtualToDefault0 < ActiveRecord::Migration[5.2]
  def change
    Event.select {|e| e.update_columns(max_virtual: 0) if e.max_virtual.nil? }
    change_column :events, :max_virtual, :integer, null: false, default: 0
  end
end
