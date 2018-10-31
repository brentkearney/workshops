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
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
    Event.destroy_all
  end

  describe '.invite' do
    before do
      @invitation = create(:invitation)
    end

    before :each do
      InvitationMailer.invite(@invitation).deliver_now
      @delivery = ActionMailer::Base.deliveries.last
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
  end
end
