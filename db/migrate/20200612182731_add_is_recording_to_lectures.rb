class AddIsRecordingToLectures < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :is_recording, :boolean, default: false
  end
end
