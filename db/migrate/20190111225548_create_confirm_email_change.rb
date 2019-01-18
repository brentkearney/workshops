class CreateConfirmEmailChange < ActiveRecord::Migration[5.2]
  def change
    create_table :confirm_email_changes do |t|
      t.references :replace_person, references: :person
      t.references :replace_with, references: :person
      t.string :replace_email
      t.string :replace_with_email
      t.string :replace_code
      t.string :replace_with_code
      t.boolean :confirmed, default: false

      t.timestamps
    end
    add_index :confirm_email_changes, :replace_code
    add_index :confirm_email_changes, :replace_with_code
  end
end
