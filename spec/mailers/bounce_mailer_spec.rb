# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe BounceMailer, type: :mailer do
  let(:params) do
  {
    to: ['username@example.com'],
    from: 'Webmaster <webmaster@example.net>',
    subject: 'Testing email processing',
    text: 'A Test Message.',
    Date: "Tue, 25 Sep 2018 16:17:17 -0600"
  }
  end

  let(:event) { create(:event) }

  def expect_email_was_sent
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  before :each do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after :each do
    ActionMailer::Base.deliveries.clear
  end

  describe '.invalid_event_code' do
    before do
      BounceMailer.invalid_event_code(params).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'From: webmaster_email' do
      from_address = GetSetting.site_email('webmaster_email')
      expect(@sent_message.from).to include(from_address)
    end

    it 'To: sender of message' do
      from_email = Mail::Address.new(params[:from])
      expect(@sent_message.to).to eq([from_email.address])
    end

    it 'Subject: Bounce notice + original subject' do
      subject = 'Bounce notice: ' + params[:subject]
      expect(@sent_message.subject).to eq(subject)
    end
  end

  describe '.non_member' do
    before do
      maillist = event.code + '@example.com'
      BounceMailer.non_member(params.merge(to: maillist)).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'From: webmaster_email' do
      from_address = GetSetting.site_email('webmaster_email')
      expect(@sent_message.from).to include(from_address)
    end

    it 'To: sender of message' do
      from_email = Mail::Address.new(params[:from])
      expect(@sent_message.to).to eq([from_email.address])
    end

    it 'Subject: Bounce notice + original subject' do
      subject = 'Bounce notice: ' + params[:subject]
      expect(@sent_message.subject).to eq(subject)
    end

    it 'Body contains reference to event code' do
      expect(@sent_message.body).to include(event.code)
    end
  end

  describe '.unauthorized_subgroup' do
    before do
      params[:to] = event.code + '-declined@example.com'
      params[:event_code] = event.code
      BounceMailer.unauthorized_subgroup(params).deliver_now
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'From: webmaster_email' do
      from_address = GetSetting.site_email('webmaster_email')
      expect(@sent_message.from).to include(from_address)
    end

    it 'To: sender of message' do
      from_email = Mail::Address.new(params[:from])
      expect(@sent_message.to).to eq([from_email.address])
    end

    it 'Subject: Bounce notice + original subject' do
      subject = 'Bounce notice: ' + params[:subject]
      expect(@sent_message.subject).to eq(subject)
    end

    it 'Body contains reference to event code' do
      expect(@sent_message.body).to include(event.code)
    end
  end

  describe '.bounced_email' do
    let(:bounce_params) do
      {
        'event-data' => {
          'message' => {
            'headers' => {
              'from' => params[:from],
              'to' => params[:to].last,
              'subject' => params[:subject],
              'X-WS-Mailer' => {
                'sender' => 'Bob Smith',
                'event' => event.code
              }
            }
          },
          'delivery-status' => {
            'code' => 550,
            'description' => 'Unable to deliver',
            'message' => 'Recipient not found'
          }
        }
      }
    end

    before do
      EmailBounce.new(bounce_params).process
      @sent_message = ActionMailer::Base.deliveries.first
    end

    it 'sends email' do
      expect_email_was_sent
    end

    it 'From: webmaster_email' do
      from_address = GetSetting.site_email('webmaster_email')
      expect(@sent_message.from).to include(from_address)
    end

    it 'To: bounce address from settings' do
      to_email = GetSetting.site_email('bounce_address')
      expect(@sent_message.to).to eq([to_email])
    end

    it 'Subject: Bounce notice + original subject' do
      subject = 'Bounce notice: ' + params[:subject]
      expect(@sent_message.subject).to eq(subject)
    end

    it 'Body contains reference to event code, sender, recipient' do
      expect(@sent_message.body).to include(event.code)
      expect(@sent_message.body).to include('Bob Smith')
      expect(@sent_message.body).to include(params[:to].last)
    end

    it 'Body contains bounce status messages' do
      expect(@sent_message.body).to include('550')
      expect(@sent_message.body).to include('Unable to deliver')
      expect(@sent_message.body).to include('Recipient not found')
    end
  end
end
