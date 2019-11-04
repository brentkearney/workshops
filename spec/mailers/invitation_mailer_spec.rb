# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe InvitationMailer, type: :mailer do
  def expect_email_was_sent
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  before :each do
    @template = 'Not Yet Invited'
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe '.invite' do
    before do
      membership = create(:membership, attendance: 'Not Yet Invited')
      @invitation = create(:invitation, membership: membership)
    end

    before :each do
      InvitationMailer.invite(@invitation, @template).deliver_now
      @delivery = ActionMailer::Base.deliveries.last
      expect(@delivery).not_to be_nil
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'To: given member, subject: event_code' do
      expect(@delivery.to_addrs.first).to eq(@invitation.membership.person.email)
      expect(@delivery.subject).to include(@invitation.membership.event.code)
    end

    it "message body includes participant's name" do
      participant_name = @invitation.membership.person.dear_name
      expect(@delivery.text_part).to have_text(participant_name)
    end

    it 'message body includes the invitation code' do
      expect(@delivery.text_part).to have_text(@invitation.code)
    end

    it 'message body contains event name' do
      event_name = @invitation.membership.event.name
      expect(@delivery.text_part).to have_text(event_name)
    end

    it 'headers include the senders name and event code' do
      expect(@delivery.header).to have_text(@invitation.membership.event.code)
      expect(@delivery.header).to have_text(@invitation.invited_by)
    end
  end

  describe 'RSVP deadline' do
    before do
      @invitation = create(:invitation)
    end

    it 'sets date to 4 weeks in advance' do
      event = @invitation.membership.event
      event.start_date = Date.current + 5.months
      event.end_date = Date.current + 5.months + 5.days
      event.save

      InvitationMailer.invite(@invitation, @template).deliver_now
      delivery = ActionMailer::Base.deliveries.last

      rsvp_date = (Date.current + 4.weeks).strftime('%B %-d, %Y')
      expect(delivery.text_part).to have_text("before #{rsvp_date}")
    end

    it 'sets date to Tuesday before workshop if event is < 10 days away' do
      event = @invitation.membership.event
      event.start_date = Date.current + 8.days
      event.end_date = Date.current + 8.days + 5.days
      event.save

      InvitationMailer.invite(@invitation, @template).deliver_now
      delivery = ActionMailer::Base.deliveries.last

      rsvp_date = event.start_date.prev_week(:tuesday).strftime('%B %-d, %Y')
      expect(delivery.text_part).to have_text("before #{rsvp_date}")
    end

    it 'sets date to 21 days in advance if event is < 3 months, 5 days away' do
      event = @invitation.membership.event
      event.start_date = Date.current + 3.months
      event.end_date = Date.current + 3.months + 5.days
      event.save

      InvitationMailer.invite(@invitation, @template).deliver_now
      delivery = ActionMailer::Base.deliveries.last

      rsvp_date = (Date.current + 21.days).strftime('%B %-d, %Y')
      expect(delivery.text_part).to have_text("before #{rsvp_date}")
    end
  end
end
