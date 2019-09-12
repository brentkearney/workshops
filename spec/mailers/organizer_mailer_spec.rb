# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe OrganizerMailer, type: :mailer do
  def expect_email_was_sent
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  before :each do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
    Event.destroy_all
  end

  describe '.rsvp_notice' do
    before do
      @organizer = create(:membership, role: 'Contact Organizer')
      @participant = create(:membership, event: @organizer.event,
                                         attendance: 'Invited')
      @participant.attendance = 'Confirmed'
      @participant.save
    end

    before :each do
      args = { 'attendance_was' => 'Invited',
               'attendance' => 'Confirmed',
               'organizer_message' => 'Foo bar' }
      OrganizerMailer.rsvp_notice(@participant, args).deliver_now
      @header = ActionMailer::Base.deliveries.first
      @mail_object = ActionMailer::Base.deliveries.last
      puts "Data:\n#{ActionMailer::Base.deliveries.last.header.to_s}"
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'To: given organizer, Subject: event_code' do
      expect(@header.to).to include(@organizer.person.email)
      expect(@header.subject).to include(@organizer.event.code)
    end

    it "message body includes participant's name & email" do
      # recipient = @mail_object[:substitution_data][:member_name]
      # email = @mail_object[:substitution_data][:member_email]
      header = @mail_object.header.to_s
      expect(header).to include(@participant.person.name)
      expect(header).to include(@participant.person.email)
    end

    it "message body includes participant's current and previous status" do
      # msg = @mail_object[:substitution_data][:attendance_msg]
      expect(msg).to have_text(@participant.attendance_was)
      expect(msg).to have_text(@participant.attendance)
    end

    it 'message body includes message to organizer' do
      # msg = @mail_object[:substitution_data][:message_to_organizer]
      expect(msg).to eq('Foo bar')
    end
  end
end
