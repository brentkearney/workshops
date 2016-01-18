class RenameLecturePublishColumn < ActiveRecord::Migration
  def change
    rename_column :lectures, :publish, :do_not_publish
  end
end
