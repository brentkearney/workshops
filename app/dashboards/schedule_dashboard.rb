require "administrate/base_dashboard"

class ScheduleDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    event: Field::BelongsTo,
    lecture: Field::BelongsTo,
    id: Field::Number,
    start_time: Field::DateTime.with_options(format: "%Y-%m-%d @ %H:%M"),
    end_time: Field::DateTime.with_options(format: "%H:%M"),
    name: Field::String,
    description: Field::Text,
    location: Field::String,
    updated_by: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    staff_item: Field::Boolean,
    earliest: Field::DateTime,
    latest: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :event,
    :name,
    :start_time,
    :end_time,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :event,
    :lecture,
    :start_time,
    :end_time,
    :name,
    :description,
    :location,
    :updated_by,
    :created_at,
    :updated_at,
    :staff_item,
    :earliest,
    :latest,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :event,
    :lecture,
    :start_time,
    :end_time,
    :name,
    :description,
    :location,
    :updated_by,
    :staff_item,
    :earliest,
    :latest,
  ].freeze

  # Overwrite this method to customize how schedules are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(schedule)
    "#{schedule.start_time.strftime("%Y-%m-%d %H:%M")}"
  end
end
