class AddJtiToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :jti, :string

    # populate jti so we can make it not nullable
    User.all.each { |user| user.update_column(:jti, SecureRandom.uuid) }
    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end
end
