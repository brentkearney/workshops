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
    before do
      @er = ErrorReport.new(self.class, @event)
    end
    
    it '.add accepts objects, instance.errors retrieves the object and its errors' do
      3.times do
        person = build(:person, lastname: '')
        @er.add(person)
      end

      expect(@er.errors).not_to be_empty
      expect(@er.errors).to be_a(Hash)
      expect(@er.errors['Person']).not_to be_empty
      @er.errors['Person'].each do |p|
        expect(p.message).to eq(["Lastname can't be blank"])
        expect(p.object).to be_a(Person)
      end
    end
    
    it '.add accepts custom error messages' do
      person = build(:person)

      @er.add(person, 'Custom error message')

      expect(@er.errors['Person'].first.message).to eq('Custom error message')
    end
  end

  describe '.send_report' do
    context 'from SyncMembers' do
      before do
        @er = ErrorReport.new('SyncMembers', @event)
      end

      it 'notifies sysadmin of LegacyConnector errors' do
        lc = FakeLegacyConnector.new
        mailer = double('mailer')
        mailer.tap do |mail|
          allow(mailer).to receive(:deliver_now).and_return(true)
          allow(StaffMailer).to receive(:notify_sysadmin).and_return(mailer)
        end

        @er.add(lc, 'Error connecting to remote API')
        @er.send_report

        expect(StaffMailer).to have_received(:notify_sysadmin)
      end

      it 'notifies staff of Person and Membership errors' do
        mailer = double('mailer')
        mailer.tap do |mail|
          allow(mailer).to receive(:deliver_now).and_return(true)
          allow(StaffMailer).to receive(:event_sync).and_return(mailer)
        end
        person = build(:person, lastname: '')
        membership = build(:membership, event: @event, person: nil)

        @er.add(person)
        @er.add(membership)
        @er.send_report

        expect(StaffMailer).to have_received(:event_sync)
      end

      context 'overlapping Membership and Person errors' do
        before do
          mailer = double('mailer')
          mailer.tap do |mail|
            allow(mailer).to receive(:deliver_now).and_return(true)
            allow(StaffMailer).to receive(:event_sync).and_return(mailer)
          end
        end

        it 'omits the Membership error if it is the same as the Person error' do
          person = build(:person, affiliation: '')
          membership = build(:membership, person: person, event: @event) #, arrival_date: '1970-01-01')
          @er.add(person)
          @er.add(membership)

          person_message = @er.errors['Person'].first.message
          legacy_url = Global.config.legacy_person + "#{person.legacy_id}"
          error_message = "* #{person.name}: #{person_message}\n"
          error_message << "   -> #{legacy_url}\n\n"

          @er.send_report
          expect(StaffMailer).to have_received(:event_sync).with(@event, error_message)
        end

        it 'includes the Membership error if it has messages additional to the Person error' do
          person = build(:person, affiliation: '')
          membership = build(:membership, person: person, event: @event, arrival_date: '1970-01-01')
          @er.add(person)
          @er.add(membership)

          person_message = @er.errors['Person'].first.message
          legacy_url = Global.config.legacy_person + "#{person.legacy_id}"
          error_message = "* #{person.name}: #{person_message}\n"
          error_message << "   -> #{legacy_url}\n\n"

          membership_message = @er.errors['Membership'].first.message
          legacy_url = Global.config.legacy_person + "#{membership.person.legacy_id}" + '&ps=events'
          error_message << "* Membership of #{membership.person.name}: #{membership_message}\n"
          error_message << "   -> #{legacy_url}\n\n"

          @er.send_report
          expect(StaffMailer).to have_received(:event_sync).with(@event, error_message)
        end
      end


      it 'does not send message if there are no errors' do
        person = create(:person)

        @er.add(person)
        @er.send_report

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end
end
