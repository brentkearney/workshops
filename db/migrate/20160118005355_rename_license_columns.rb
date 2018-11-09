class RenameLicenseColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :lectures, :birs_license, :hosting_license
    rename_column :lectures, :ubc_license, :archiving_license
    rename_column :lectures, :birs_release, :hosting_release
    rename_column :lectures, :ubc_release, :archiving_release
  end
end
