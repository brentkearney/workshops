class AddIndexToPeople < ActiveRecord::Migration
  def change
    add_index :people, :email, unique: true
  end
end
