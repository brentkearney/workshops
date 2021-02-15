class RenameFormatToEventFormat < ActiveRecord::Migration[5.2]
  def change
    rename_column :events, :format, :event_format
  end
end
