class CreateSchedules < ActiveRecord::Migration[4.2]
  def change
    create_table :schedules do |t|
      t.references :event, index: true, foreign_key: true, null: false
      t.integer :lecture_id
      t.datetime :start_time
      t.datetime :end_time
      t.string :name
      t.text :description
      t.string :location
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
