class AddColumnsToLectures < ActiveRecord::Migration[4.2]
  def change
    add_column :lectures, :cmo_license, :string
    add_column :lectures, :keywords, :string
    add_column :lectures, :legacy_id, :integer
  end
end
