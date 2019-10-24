class AddMaxObserversToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :max_observers, :integer, default: 0, null: false
  end
end
