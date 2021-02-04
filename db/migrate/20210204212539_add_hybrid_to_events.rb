class AddHybridToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :hybrid, :boolean, default: true
  end
end
