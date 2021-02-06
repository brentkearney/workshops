class AddFormatToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :format, :text
  end
end
