# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

# Event Maillist handler
describe 'EventMaillist' do
  let(:params) do
  {
    to: ['some-identifier@example.com'],
    from: 'Webmaster <webmaster@example.net>',
    subject: 'Testing email processing',
    text: 'A Test Message.',
    Date: "Tue, 25 Sep 2018 16:17:17 -0600"
  }
  end

  subject { Griddler::Email.new(params) }

  before do
    @event = create(:event)
    @member = create(:membership, event: @event, attendance: 'Confirmed')
  end

  it '.initialize' do
    expect(EventMaillist.new(subject, @event).class).to eq(EventMaillist)
  end

  context '.send_message' do
    before do
      domain = GetSetting.site_setting('app_url').gsub(/^.+\/\//, '')
      params[:to] = [@event.code + '@' + domain]
      @maillist = EventMaillist.new(subject, @event)
    end

    it 'sends email and formatted recipients to MaillistMailer' do
      allow(MaillistMailer).to receive(:workshop_maillist)
      recipients = [{ address: { email: @member.person.email, name: "#{@member.person.name}" } }]
      message = {
        from: params[:from],
        subject: params[:subject],
        body: params[:text],
        date: params[:date]
      }
      @maillist.send_message
      expect(MaillistMailer).to have_received(:workshop_maillist).with(message, recipients)
    end
  end
end
