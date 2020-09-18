# app/models/sentmail.rb
#
# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Sentmail < ApplicationRecord
  validates :message_id, presence: true
  validate :one_message_per_recipient


  def one_message_per_recipient
    if Sentmail.where(message_id: message_id, recipient: recipient).count > 0
      errors.add(:message_id, "this message was already sent to #{recipient}.")
    end
  end
end
