class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.references :membership, index: true, foreign_key: true
      t.integer :invited_by, index: true
      t.string :code, unique: true, null: false
      t.datetime :expires
      t.datetime :invited_on
      t.datetime :used_on

      t.timestamps null: false
    end
    add_foreign_key :invitations, :people, column: :invited_by
  end
end
