class AddUrlsToLectures < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :watch_url, :string
    add_column :lectures, :video_url, :string
  end
end
