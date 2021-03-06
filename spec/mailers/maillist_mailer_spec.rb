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

  before do
    @msg = {
      location: 'EO',
      from: '"Email Sender" <sender@domain.com>',
      to: '"Workshop Maillist" <19w5020@example.com>',
      subject: '[19w5020] Test subject',
      body: 'This is a test message.',
      email_parts: {
        text_body: 'This is a test message.',
        html_body: '',
        inline_attachments: {}
      }
    }
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

  describe '.workshop_organizers' do
    before do
      @recipients = { to: %Q("Contact Organizer" <contact@example.com>), cc: %Q("Supporting Organizer 1" <org1@example.com>, "Supporting Organizer 2" <org2@example.com>) }
      @resp = MaillistMailer.workshop_organizers(@msg, @recipients).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'responds with a Mail::Message object' do
      expect(@resp.class).to eq(Mail::Message)
    end

    it 'From: is specified in Settings:Email:maillist_from' do
      location = @msg[:location]
      from_email = GetSetting.email(location, 'maillist_from')
      email_obj = Mail::Address.new(from_email)
      expect(@sent_message.from).to eq([email_obj.address])
    end

    it 'From: is the same as the original sender, if domain matches local' do
      domain = GetSetting.site_setting('email_domain')
      from_address = "staff@#{domain}"
      @msg.merge!({from: from_address})
      MaillistMailer.workshop_organizers(@msg, @recipients).deliver_now
      expect(ActionMailer::Base.deliveries.last.from).to eq(["#{from_address}"])
    end

    it 'Reply-to: is the sender' do
      expect(@msg[:from]).to include(@sent_message.reply_to.first)
    end

    it 'To: is the given recipient' do
      expect(@sent_message.to).to eq(@sent_message.to_addrs)
    end

    it 'Message body is the passed-in body' do
      expect(@sent_message.body.raw_source.strip).to eq(@msg[:body].strip)
    end
  end

  describe '.workshop_maillist' do
    before do
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

    it 'From: is specified in Settings:Email:maillist_from' do
      location = @msg[:location]
      from_email = GetSetting.email(location, 'maillist_from')
      email_obj = Mail::Address.new(from_email)
      expect(@sent_message.from).to eq([email_obj.address])
    end

    it 'From: is the same as the original sender, if domain matches local' do
      domain = GetSetting.site_setting('email_domain')
      from_address = "staff@#{domain}"
      @msg.merge!({from: from_address})
      MaillistMailer.workshop_maillist(@msg, @recipient).deliver_now
      expect(ActionMailer::Base.deliveries.last.from).to eq(["#{from_address}"])
    end

    it 'Reply-to: is the sender' do
      expect(@msg[:from]).to include(@sent_message.reply_to.first)
    end

    it 'To: is the given recipient' do
      expect(@sent_message.to).to eq(@sent_message.to_addrs)
    end

    it 'Message body is the passed-in body' do
      expect(@sent_message.body.raw_source.strip).to eq(@msg[:body].strip)
    end
  end
end
