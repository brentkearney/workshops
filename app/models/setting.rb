# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Setting < RailsSettings::Base
  validate :unique_and_present_var
  attr_accessor :flash_error
  namespace Rails.env

  def name(key)
    loc = Setting.find_by_var('Locations').value[key.to_sym]
    loc.nil? ? key : loc['Name']
  end

  private

  def unique_and_present_var
    if self.var.blank?
      self.flash_error = 'Setting Name must not be blank'
      errors.add(:var, '- Setting Name must not be blank')
    end

    new_setting = self.value.delete(:new_setting)
    self.value = self.value.except(:new_setting)
    if new_setting
      unless Setting.find_by_var(self.var).nil?
        self.flash_error = 'Setting Name must be unique'
        errors.add(:var, '- Setting Name must be unique')
      end
    end
  end
end
