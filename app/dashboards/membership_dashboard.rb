require "administrate/base_dashboard"

class MembershipDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    event: Field::BelongsTo,
    person: Field::BelongsTo,
    invitation: Field::HasOne,
    id: Field::Number,
    arrival_date: Field::DateTime,
    departure_date: Field::DateTime,
    role: Field::String,
    attendance: Field::String,
    replied_at: Field::DateTime,
    share_email: Field::Boolean,
    org_notes: Field::Text,
    staff_notes: Field::Text,
    updated_by: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    sent_invitation: Field::Boolean,
    own_accommodation: Field::Boolean,
    has_guest: Field::Boolean,
    guest_disclaimer: Field::Boolean,
    special_info: Field::String,
    stay_id: Field::String,
    billing: Field::String,
    reviewed: Field::Boolean,
    room: Field::String,
    invited_by: Field::String,
    invited_on: Field::DateTime,
    share_email_hotel: Field::Boolean,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :event,
    :person,
    :invitation,
    :id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :event,
    :person,
    :invitation,
    :id,
    :arrival_date,
    :departure_date,
    :role,
    :attendance,
    :replied_at,
    :share_email,
    :org_notes,
    :staff_notes,
    :updated_by,
    :created_at,
    :updated_at,
    :sent_invitation,
    :own_accommodation,
    :has_guest,
    :guest_disclaimer,
    :special_info,
    :stay_id,
    :billing,
    :reviewed,
    :room,
    :invited_by,
    :invited_on,
    :share_email_hotel,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :event,
    :person,
    :invitation,
    :arrival_date,
    :departure_date,
    :role,
    :attendance,
    :replied_at,
    :share_email,
    :org_notes,
    :staff_notes,
    :updated_by,
    :sent_invitation,
    :own_accommodation,
    :has_guest,
    :guest_disclaimer,
    :special_info,
    :stay_id,
    :billing,
    :reviewed,
    :room,
    :invited_by,
    :invited_on,
    :share_email_hotel,
  ].freeze

  # Overwrite this method to customize how memberships are displayed
  # across all pages of the admin dashboard.
  #
   #def display_resource(membership)
    # "Membership ##{membership.id}"
   #end
end
