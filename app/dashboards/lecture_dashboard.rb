require "administrate/base_dashboard"

class LectureDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    event: Field::BelongsTo,
    person: Field::BelongsTo,
    schedule: Field::HasOne,
    id: Field::Number,
    title: Field::String,
    start_time: Field::DateTime.with_options(format: "%Y-%m-%d %H:%M"),
    end_time: Field::DateTime,
    abstract: Field::Text,
    notes: Field::Text,
    filename: Field::String,
    room: Field::String,
    do_not_publish: Field::Boolean,
    tweeted: Field::Boolean,
    hosting_license: Field::Text,
    archiving_license: Field::Text,
    hosting_release: Field::Boolean,
    archiving_release: Field::Boolean,
    authors: Field::String,
    copyright_owners: Field::String,
    publication_details: Field::String,
    updated_by: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    cmo_license: Field::String,
    keywords: Field::String,
    legacy_id: Field::Number,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :event,
    :person,
    :start_time,
    :schedule,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :event,
    :person,
    :title,
    :start_time,
    :end_time,
    :abstract,
    :notes,
    :filename,
    :room,
    :do_not_publish,
    :tweeted,
    :hosting_license,
    :archiving_license,
    :hosting_release,
    :archiving_release,
    :authors,
    :copyright_owners,
    :publication_details,
    :updated_by,
    :created_at,
    :updated_at,
    :cmo_license,
    :keywords,
    :legacy_id,
    :schedule,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :event,
    :person,
    :title,
    :start_time,
    :end_time,
    :abstract,
    :notes,
    :filename,
    :room,
    :do_not_publish,
    :tweeted,
    :hosting_license,
    :archiving_license,
    :hosting_release,
    :archiving_release,
    :authors,
    :copyright_owners,
    :publication_details,
    :updated_by,
    :cmo_license,
    :keywords,
    :legacy_id,
    :schedule,
  ].freeze

  # Overwrite this method to customize how lectures are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(lecture)
    "#{lecture.title}"
  end
end
