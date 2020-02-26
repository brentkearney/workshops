class AddGrantsToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :grants, :string
  end
end
