class RenameLecturePublishColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :lectures, :publish, :do_not_publish
  end
end
