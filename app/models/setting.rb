# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Setting < RailsSettings::Base
  TTL = 1.minute
  attr_accessor :new_field, :new_value
  before_save :add_or_remove_locations, :merge_fields #, :convert_type
  after_update :rewrite_cache
  # after_create :rewrite_cache
  namespace Rails.env

  def name(key)
    location = Setting.Locations
    if location.key? key
      location[key][:Name]
    else
      key
    end
  end

  def rewrite_cache
    Rails.cache.write("settings:#{self.var}", self.value, expires_in: TTL)
  end

  def add_or_remove_locations
    if self.var = 'Locations'
      remove_location if self.value.keys.include? 'remove_location'
      add_location if self.value.keys.include? 'new_location'
    end
  end

  def merge_fields
    unless self.value.empty?
      if self.value.first.second.is_a?(Hash)
        settings = self.value.except(:'')
        self.value.except(:'').each do |param_key, param_value|
          new_field = param_value.delete(:new_field)
          new_value = param_value.delete(:new_value)
          param_value.merge!("#{new_field}": new_value) unless new_field.blank?
          settings[:"#{param_key}"] = param_value

          new_key = param_value.delete(:new_key)
          if !new_key.blank? && new_key != param_key
            settings[:"#{new_key}"] = settings.delete("#{param_key}")
          end
        end

        self.value = settings
      else
        settings = self.value
        new_string_field = settings.delete(:new_field)
        new_string_value = settings.delete(:new_value)
        self.value = settings.merge("#{new_string_field}": new_string_value)
      end
    end
  end

  def add_location
    Rails.logger.debug "\n\n|||||||||||||||||||| add_location START ||||||||||||||||||||\n"
    self_value = self.value
    new_location_key = self_value.delete(:new_location)
    # self.value = self_value
    logger.debug "self_value is: #{self_value}"
    logger.debug "self.value is: #{self.value}"

    Rails.logger.debug "Adding new Location key: #{new_location_key}\n"

    (Setting.get_all.keys - ['Site']).each do |section|
      logger.debug "\n\n=> Processing section: #{section}..............\n"
      setting = Setting.find_by(var: section)
      section_settings = setting.value
     
      empty_fields = {}
      unless section_settings.keys.empty?
        section_settings[section_settings.keys.first].each do |key, value|
          empty_fields[:"#{key}"] = ''
        end
      end
      new_location = {:"#{new_location_key}" => empty_fields}

      logger.debug "New location to merge: #{new_location}"
      logger.debug "Will merge with: #{section_settings}\n"

      new_value = section_settings.merge(new_location)
      logger.debug "New #{section} value will be: #{new_value}"
      setting.value = new_value
      setting.save!
    end
    Rails.logger.debug "\n|||||||||||||||||||| add_location END ||||||||||||||||||||\n\n"
  end

  def remove_location
    settings = self.value
    location_key = settings.delete(:remove_location)
    self.value = settings.except(:"#{location_key}")
  end

  # Save arrays as arrays (not strings)
  def convert_type
    self.value.each do |param_name, param_value|
      if param_value =~ /^\[(.+)\]$/
        param_value = param_value.gsub(/^\[|"|'|\]$/, '').split(',').map(&:strip)
        self.value = self.value.merge("#{param_name}": param_value)
      end
    end
  end
end
