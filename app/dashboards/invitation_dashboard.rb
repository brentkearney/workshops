require "administrate/base_dashboard"

class InvitationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    membership: Field::BelongsTo,
    id: Field::Number,
    invited_by: Field::String,
    code: Field::String,
    expires: Field::DateTime,
    invited_on: Field::DateTime,
    used_on: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :membership,
    :id,
    :invited_by,
    :code,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :membership,
    :id,
    :invited_by,
    :code,
    :expires,
    :invited_on,
    :used_on,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :membership,
    :invited_by,
    :code,
    :expires,
    :invited_on,
    :used_on,
  ].freeze

  # Overwrite this method to customize how invitations are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(invitation)
  #   "Invitation ##{invitation.id}"
  # end
end
