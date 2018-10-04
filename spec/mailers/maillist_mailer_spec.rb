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
        from: '"Random Sender" <random@example.com>',
        subject: 'Test subject',
        body: 'This is a test message.',
        date: 'Tue, 25 Sep 2018 16:17:17 -0600'
      }
      @recipients = [
        { address: { email: 'one@test.ca', name: "Test User" } },
        { address: { email: 'two@test.ca', name: "Test User2" } },
        { address: { email: 'three@test.ca', name: "Test User3" } }
      ]
      @resp = MaillistMailer.workshop_maillist(@msg, @recipients).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'responds with a Mail::Message object' do
      expect(@resp.class).to eq(Mail::Message)
    end

    it 'From: is the sender' do
      from_email = Mail::Address.new(@msg[:from])
      expect(@sent_message.from).to eq([from_email.address])
    end

    it 'To: is the recipient list' do
      recip_string = ''
      @recipients.each do |r|
        recip_string << r.to_s + ', '
      end
      expect(@sent_message.to).to eq(recip_string.gsub!(/,\ \z/, ''))
    end

    it 'Message body is the passed-in body (no template)' do
      expect(@sent_message.body.raw_source).to eq(@msg[:body])
    end
  end
end
