class CreateMemberships < ActiveRecord::Migration[4.2]
  def change
    create_table :memberships do |t|
      t.references :event, index: true, foreign_key: true
      t.references :person, index: true, foreign_key: true
      t.date :arrival_date
      t.date :departure_date
      t.string :role
      t.string :attendance
      t.datetime :replied_at
      t.boolean :share_email, :default => true
      t.text :org_notes
      t.text :staff_notes
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
