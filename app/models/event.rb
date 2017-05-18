# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Event < ActiveRecord::Base
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :person
  has_many :schedules, dependent: :destroy
  has_many :lectures

  before_save :clean_data

  validates :name, :start_date, :end_date, :location, :max_participants,
            :time_zone, presence: true
  validates :short_name, presence: true, if: :has_long_name
  validates :event_type, presence: true, if: :check_event_type
  validate :starts_before_ends
  validates_inclusion_of :time_zone, in: ActiveSupport::TimeZone.zones_map.keys
  unless Setting.Site.blank?
    validates :code, uniqueness: true, format: {
      with: /#{Setting.Site['code_pattern']}/,
      message: "- invalid code format. Must match:
              #{Setting.Site['code_pattern']}"
    }
  end

  # app/models/concerns/event_decorators.rb
  include EventDecorators

  # Find by code
  def to_param
    code
  end

  def self.find(param)
    param =~ /\D/ ? find_by_code(param) : super
  end

  scope :past, -> { where("end_date < ? AND template = ?",
    Date.current, false).order(:start_date) }
  scope :future, -> { where("end_date >= ? AND template = ?",
    Date.current, false).order(:start_date) }
  scope :year, ->(year) { where("start_date >= '?-01-01' AND end_date <= '?-12-31' AND template = ?", year.to_i, year.to_i, false) }
  scope :location, ->(location) { where("location = ? AND template = ?", location, false) }

  scope :kind, ->(kind) {
    if kind == 'Research in Teams'
      # RITs stay plural
      where("event_type = ? AND template = ?", 'Research in Teams', false).order(:start_date)
    else
      where("event_type = ? AND template = ?", kind.titleize.singularize, false).order(:start_date)
    end
  }

  def self.templates
    where('template = ?', true)
  end

  def check_event_type
    if Setting.Site['event_types'].include?(event_type)
      return true
    else
      types = Setting.Site['event_types'].join(', ')
      errors.add(:event_type, "- event type must be one of: #{types}")
      return false
    end
  end

  def has_long_name
    if name && name.length > 68
      if short_name.blank?
        errors.add(:short_name, "- if the name is > 68 characters, a shorter name is required to fit on name tags")
      elsif short_name.length > 68
        errors.add(:short_name, "must be less than 68 characters long")
      end
    end
  end

  def self.years
    all.map {|e| e.start_date.year.to_s}.uniq.sort
  end

  def starts_before_ends
    if (start_date && end_date) && (start_date > end_date)
      errors.add(:start_date, "- event must begin before it ends")
    end
  end

  private

  def clean_data
    attributes.each_value { |v| v.strip! if v.respond_to? :strip! }
  end
end
