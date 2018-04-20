# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe InvitationMailer, type: :mailer do
  # Uses SparkPost now

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
      @sparkpost_data = ActionMailer::Base.deliveries.last.sparkpost_data
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'To: given member, subject: event_code' do
      header = ActionMailer::Base.deliveries.last
      expect(header.to).to include(@invitation.membership.person.email)
      expect(header.subject).to include(@invitation.membership.event.code)
    end

    it "message body includes participant's name" do
      recipient = @sparkpost_data[:substitution_data][:person_name]
      expect(recipient).to have_text(@invitation.membership.person.dear_name)
    end

    it 'message body includes the invitation code' do
      rsvp_link = @sparkpost_data[:substitution_data][:rsvp_link]
      expect(rsvp_link).to have_text(@invitation.code)
    end

    it 'message body contains event name' do
      event_code = @sparkpost_data[:substitution_data][:event_name]
      expect(event_code).to eq(@invitation.membership.event.name)
    end
  end
end
