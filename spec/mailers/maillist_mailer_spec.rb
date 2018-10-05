# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe MaillistMailer, type: :mailer do
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

  describe '.workshop_maillist' do
    before do
      @msg = {
        from: '"Workshops" <workshops@example.com>',
        subject: '[19w5020] Test subject',
        body: 'This is a test message.',
      }
      @recipient = %Q("Test User" <testuser@example.com>)
      @resp = MaillistMailer.workshop_maillist(@msg, @recipient).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'responds with a Mail::Message object' do
      expect(@resp.class).to eq(Mail::Message)
    end

    it 'From: is the specified from address' do
      from_email = Mail::Address.new(@msg[:from])
      expect(@sent_message.from).to eq([from_email.address])
    end

    it 'To: is the given recipient' do
      expect(@sent_message.to).to eq(@sent_message.to_addrs)
    end

    it 'Message body is the passed-in body (no template)' do
      expect(@sent_message.body.raw_source).to eq(@msg[:body])
    end
  end
end
