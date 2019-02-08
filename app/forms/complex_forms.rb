# app/forms/complex_forms.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Top-level class for custom form classes
class ComplexForms
  include ActiveModel::Model

  def to_key
  end

  def to_model
    self
  end

  def persisted?
    false
  end

  def read_attribute_for_validation(key)
    @attributes[key]
    send(key)
  end

  def self.human_attribute_name(attr, options = {})
    attr
  end

  def self.lookup_ancestors
    [self]
  end
end
