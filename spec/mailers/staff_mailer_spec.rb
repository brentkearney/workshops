# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe StaffMailer, type: :mailer do
  before :each do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
    Event.destroy_all
  end

  describe '.event_sync' do
    it 'sends email to program coordinator and system administrator' do
      event = create(:event, code: '15w6661', location: 'BIRS')

      @sync_errors = { 'Event' => event, 'People' => Array.new, 'Memberships' => Array.new }
      StaffMailer.event_sync(event, @sync_errors).deliver_now

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(Global.email.locations.send(event.location).program_coordinator)
      expect(ActionMailer::Base.deliveries.first.cc).to include(Global.email.system_administrator)
    end
  end

  describe '.notify_sysadmin' do
    it 'sends email to system administrator' do
      @event = create(:event, code: '15w6661', location: 'BIRS')
      person = build(:person, lastname: '', email:'xxx')
      person.valid?
      error_report = ErrorReport.new(self.class, @event)
      error_report.add(person)
      @error = error_report.errors['Person'].first

      StaffMailer.notify_sysadmin(@event, @error).deliver_now

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(Global.email.system_administrator)
    end
  end

  describe '.schedule_change' do
    let(:event) { build(:event) }
    let(:original_schedule) { build(:schedule, event: event, name: 'Original name') }
    let(:new_schedule) { build(:schedule, event: event, name: 'New name') }

    before :each do
      StaffMailer.schedule_change(original_schedule, type: :update, user: 'Test User', updated_schedule: new_schedule).deliver_now
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'To: schedule_staff' do
      expect(ActionMailer::Base.deliveries.first.to).to match_array(Global.email.locations.send(event.location).schedule_staff.split(', '))
    end
  end

  describe '.nametag_update' do
    let(:event) { build(:event) }

    before :each do
      params = { short_name: 'Shorter name' }
      StaffMailer.nametag_update(original_event: event, params: params).deliver_now
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'To: nametag_updates' do
      expect(ActionMailer::Base.deliveries.first.to).to match_array(Global.email.locations.send(event.location).name_tags.split(', '))
    end
  end

  describe '.event_update' do
    let(:event) { build(:event) }

    before :each do
      params = { description: 'New description', press_release: 'New press release' }
      StaffMailer.event_update(original_event: event, params: params).deliver_now
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'To: event_updates' do
      expect(ActionMailer::Base.deliveries.first.to).to match_array(Global.email.locations.send(event.location).event_updates.split(', '))
    end

  end
end
