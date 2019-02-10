require "administrate/base_dashboard"

class EventDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    memberships: Field::HasMany,
    members: Field::HasMany.with_options(class_name: "Person"),
    schedules: Field::HasMany,
    lectures: Field::HasMany,
    id: Field::Number,
    code: Field::String,
    name: Field::Text,
    short_name: Field::String,
    start_date: Field::DateTime,
    end_date: Field::DateTime,
    event_type: Field::String,
    location: Field::String,
    description: Field::Text,
    press_release: Field::Text,
    max_participants: Field::Number,
    door_code: Field::Number,
    booking_code: Field::String,
    updated_by: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    template: Field::Boolean,
    time_zone: Field::String,
    publish_schedule: Field::Boolean,
    confirmed_count: Field::Number,
    sync_time: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :memberships,
    :members,
    :schedules,
    :lectures,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :memberships,
    :members,
    :schedules,
    :lectures,
    :id,
    :code,
    :name,
    :short_name,
    :start_date,
    :end_date,
    :event_type,
    :location,
    :description,
    :press_release,
    :max_participants,
    :door_code,
    :booking_code,
    :updated_by,
    :created_at,
    :updated_at,
    :template,
    :time_zone,
    :publish_schedule,
    :confirmed_count,
    :sync_time,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :memberships,
    :members,
    :schedules,
    :lectures,
    :code,
    :name,
    :short_name,
    :start_date,
    :end_date,
    :event_type,
    :location,
    :description,
    :press_release,
    :max_participants,
    :door_code,
    :booking_code,
    :updated_by,
    :template,
    :time_zone,
    :publish_schedule,
    :confirmed_count,
    :sync_time,
  ].freeze

  # Overwrite this method to customize how events are displayed
  # across all pages of the admin dashboard.
  #
   #def display_resource(event)
     #{}" #{event.id}"
   #end
end
