class AddPersonToUser < ActiveRecord::Migration[4.2]
  def change
    add_reference :users, :person, index: true
  end
end
