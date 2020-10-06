class AddCancelledToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :cancelled, :boolean, default: false
  end
end
