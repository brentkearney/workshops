class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :code
      t.text :name
      t.string :short_name
      t.date :start_date
      t.date :end_date
      t.string :event_type
      t.string :location
      t.text :description
      t.text :press_release
      t.integer :max_participants
      t.integer :door_code
      t.string :booking_code
      t.integer :updated_by

      t.timestamps null: false
    end
    add_index :events, :code, unique: true
  end
end
