class CreateSentmail < ActiveRecord::Migration[5.2]
  def change
    create_table :sentmails do |t|
      t.string :message_id, index: true
      t.string :sender
      t.string :recipient
      t.string :subject
      t.datetime :date
      t.timestamps null: false
    end
  end
end
