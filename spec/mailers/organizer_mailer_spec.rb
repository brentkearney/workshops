# Copyright (c) 2016 Banff International Research Station.
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
      OrganizerMailer.rsvp_notice(@participant, 'Foo bar').deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'To: given organizer' do
      expect(@sent_message.to).to include(@organizer.person.email)
    end

    it "message body includes participant's name" do
      expect(@sent_message.body).to have_text(@participant.person.name)
    end

    it "message body includes participant's current and previous status" do
      expect(@sent_message.body).to have_text(@participant.attendance_was)
      expect(@sent_message.body).to have_text(@participant.attendance)
    end

    it 'message body includes given message' do
      expect(@sent_message.body).to have_text('Foo bar')
    end
  end
end
