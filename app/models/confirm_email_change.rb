# app/models/confirm_email_change.rb
# Copyright (c) 2019 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# If user requests changing email and another record has that email,
# this will send confirmation links to both addresses to confirm ownership
# before one person record is replaced with the other
class ConfirmEmailChange < ApplicationRecord
  attr_accessor :replace_person, :replace_with
  has_many :people
  validates :replace_person, presence: true
  validates :replace_with, presence: true

  after_initialize :generate_codes
  before_save :set_emails

  def generate_codes
    if self.replace_code.blank?
      self.replace_code = SecureRandom.urlsafe_base64(10)
    end
    if self.replace_with_code.blank?
      self.replace_with_code = SecureRandom.urlsafe_base64(10)
    end
  end

  def set_emails
    self.replace_email = replace_person.email
    self.replace_with_email = replace_with.email
  end

  def send_email

  end
end
