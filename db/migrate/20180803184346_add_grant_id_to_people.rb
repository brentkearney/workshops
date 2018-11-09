class AddGrantIdToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :grant_id, :integer
  end
end
