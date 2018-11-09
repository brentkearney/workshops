class AddIndexToPeople < ActiveRecord::Migration[4.2]
  def change
    add_index :people, :email, unique: true
  end
end
