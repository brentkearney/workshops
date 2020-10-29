class AddOnlineToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :online, :boolean, default: false
  end
end
