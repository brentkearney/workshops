class AddRoomNotesToMemberships < ActiveRecord::Migration[5.2]
  def change
    add_column :memberships, :room_notes, :string
  end
end
