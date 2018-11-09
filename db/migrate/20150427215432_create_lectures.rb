class CreateLectures < ActiveRecord::Migration[4.2]
  def change
    create_table :lectures do |t|
      t.references :event, index: true, foreign_key: true, null: false
      t.references :person, index: true, foreign_key: true
      t.string :title
      t.datetime :start_time
      t.datetime :end_time
      t.text :abstract
      t.text :notes
      t.string :filename
      t.string :room
      t.boolean :publish
      t.boolean :tweeted
      t.text :birs_license
      t.text :ubc_license
      t.boolean :birs_release
      t.boolean :ubc_release
      t.string :authors
      t.string :copyright_owners
      t.string :publication_details
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
