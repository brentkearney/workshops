# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe ParticipantMailer, type: :mailer do
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

  describe '.rsvp_confirmation' do
    before do
      @invitation = create(:invitation)
      @membership = @invitation.membership
    end

    before :each do
      ParticipantMailer.rsvp_confirmation(@membership).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'From: Setting.Emails["rsvp"]' do
      from_address = GetSetting.email(@membership.event.location, 'rsvp')
      expect(@sent_message.from).to include(from_address)
    end

    it 'To: confirmed participant' do
      expect(@sent_message.to).to include(@membership.person.email)
    end

    it 'includes PDF attachment' do
      filename = @membership.event.location + '-arrival-info.pdf'
      expect(@sent_message.attachments.first.filename).to eq(filename)
    end
  end
end
