class CreatePeople < ActiveRecord::Migration[4.2]
  def change
    create_table :people do |t|
      t.string :lastname
      t.string :firstname
      t.string :salutation
      t.string :gender
      t.string :email
      t.string :cc_email
      t.string :url
      t.string :phone
      t.string :fax
      t.string :emergency_contact
      t.string :emergency_phone
      t.string :affiliation
      t.string :department
      t.string :title
      t.string :address1
      t.string :address2
      t.string :address3
      t.string :city
      t.string :region
      t.string :country
      t.string :postal_code
      t.string :academic_status
      t.string :phd_year
      t.text :biography
      t.text :research_areas
      t.integer :legacy_id
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
