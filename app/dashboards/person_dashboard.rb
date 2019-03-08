require "administrate/base_dashboard"

class PersonDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    #memberships: Field::HasMany,
    #events: Field::HasMany,
    replace_person: Field::BelongsTo.with_options(class_name: "ConfirmEmailChange"),
    replace_with: Field::BelongsTo.with_options(class_name: "ConfirmEmailChange"),
    id: Field::Number,
    lastname: Field::String,
    firstname: Field::String,
    salutation: Field::String,
    gender: Field::String,
    email: Field::String,
    cc_email: Field::String,
    url: Field::String,
    phone: Field::String,
    fax: Field::String,
    emergency_contact: Field::String,
    emergency_phone: Field::String,
    affiliation: Field::String,
    department: Field::String,
    title: Field::String,
    address1: Field::String,
    address2: Field::String,
    address3: Field::String,
    city: Field::String,
    region: Field::String,
    country: Field::String,
    postal_code: Field::String,
    academic_status: Field::String,
    phd_year: Field::String,
    biography: Field::Text,
    research_areas: Field::Text,
    legacy_id: Field::Number,
    updated_by: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    grant_id: Field::Number,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :email,
    :lastname,
    :firstname,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    #:memberships,
    #:events,
    #:replace_person,
    #:replace_with,
    #:id,
    :lastname,
    :firstname,
    :salutation,
    :gender,
    :email,
    :cc_email,
    :url,
    :phone,
    :fax,
    :emergency_contact,
    :emergency_phone,
    :affiliation,
    :department,
    :title,
    :address1,
    :address2,
    :address3,
    :city,
    :region,
    :country,
    :postal_code,
    :academic_status,
    :phd_year,
    :biography,
    :research_areas,
    :legacy_id,
    :updated_by,
    :created_at,
    :updated_at,
    :grant_id,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    #:memberships,
    #:events,
    :lastname,
    :firstname,
    :salutation,
    :gender,
    :email,
    :cc_email,
    :url,
    :phone,
    :fax,
    :emergency_contact,
    :emergency_phone,
    :affiliation,
    :department,
    :title,
    :address1,
    :address2,
    :address3,
    :city,
    :region,
    :country,
    :postal_code,
    :academic_status,
    :phd_year,
    :biography,
    :research_areas,
    :legacy_id,
    :updated_by,
    :grant_id,
  ].freeze

  # Overwrite this method to customize how people are displayed
  # across all pages of the admin dashboard.
  #
   def display_resource(person)
     "#{person.lastname+", "+ person.lastname}"
   end
end
