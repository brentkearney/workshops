require "administrate/base_dashboard"

class ConfirmEmailChangeDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    people: Field::HasMany,
    id: Field::Number,
    replace_person_id: Field::Number,
    replace_with_id: Field::Number,
    replace_email: Field::String,
    replace_with_email: Field::String,
    replace_code: Field::String,
    replace_with_code: Field::String,
    confirmed: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :people,
    :id,
    :replace_person_id,
    :replace_with_id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :people,
    :id,
    :replace_person_id,
    :replace_with_id,
    :replace_email,
    :replace_with_email,
    :replace_code,
    :replace_with_code,
    :confirmed,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :people,
    :replace_person_id,
    :replace_with_id,
    :replace_email,
    :replace_with_email,
    :replace_code,
    :replace_with_code,
    :confirmed,
  ].freeze

  # Overwrite this method to customize how confirm email changes are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(confirm_email_change)
  #   "ConfirmEmailChange ##{confirm_email_change.id}"
  # end
end
