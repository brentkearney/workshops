class RemoveColumnFromPeople < ActiveRecord::Migration[5.2]
  def change
    remove_column :people, :grant_id, :integer
  end
end
