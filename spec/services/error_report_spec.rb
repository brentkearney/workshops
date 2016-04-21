# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "ErrorReport" do
  before do
    @event = create(:event)
  end

  describe '.initialize' do
    it 'new objects have an event, a calling class (from) and .errors' do
      er = ErrorReport.new(self.class, @event)

      expect(er).to be_a(ErrorReport)
      expect(er.event).to eq(@event)
      expect(er.from).to eq(self.class)
      expect(er.errors).to be_empty
    end
  end

  describe '.add, .errors' do
    it '.add accepts objects with associated errors, .errors retrieves the object and its errors' do
      er = ErrorReport.new(self.class, @event)
      person = build(:person, lastname: '')
      person.valid?

      er.add(person)

      expect(er.errors).not_to be_empty
      expect(er.errors).to be_a(Hash)
      expect(er.errors['Person']).not_to be_empty
      expect(er.errors['Person'].first.message).to eq(["Lastname can't be blank"])
      expect(er.errors['Person'].first.object).to eq(person)
    end
  end

  describe '.send_report' do
    it 'sends email reports with Staff Mailer'
  end
end
