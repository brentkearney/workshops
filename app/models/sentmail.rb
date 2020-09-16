# app/models/sentmail.rb
#
# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Sentmail < ApplicationRecord
  validates :message_id, presence: true
end
