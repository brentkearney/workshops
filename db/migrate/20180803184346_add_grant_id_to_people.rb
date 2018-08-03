class AddGrantIdToPeople < ActiveRecord::Migration
  def change
    add_column :people, :grant_id, :integer
  end
end
