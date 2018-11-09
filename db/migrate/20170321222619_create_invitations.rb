class CreateInvitations < ActiveRecord::Migration[4.2]
  def change
    create_table :invitations do |t|
      t.references :membership, index: true, foreign_key: true
      t.string :invited_by
      t.string :code, unique: true, null: false
      t.datetime :expires
      t.datetime :invited_on
      t.datetime :used_on
      t.timestamps null: false
    end
  end
end
