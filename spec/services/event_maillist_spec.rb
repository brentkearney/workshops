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
    to: ['event_code@example.com'],
    from: 'Webmaster <webmaster@example.net>',
    subject: 'Testing email processing',
    text: 'A Test Message.',
    Date: "Tue, 25 Sep 2018 16:17:17 -0600"
  }
  end

  subject { Griddler::Email.new(params) }

  before do
    @event = create(:event)
    @event.memberships.destroy_all
    2.times do
      create(:membership, event: @event, attendance: 'Maybe')
    end
    @status = 'Maybe'
  end

  it '.initialize' do
    expect(EventMaillist.new(subject, @event, @status).class).to eq(EventMaillist)
  end

  context '.send_message' do
    before do
      domain = GetSetting.site_setting('app_url').gsub(/^.+\/\//, '')
      params[:to] = [@event.code + '@' + domain]
      @maillist = EventMaillist.new(subject, @event, @status)
    end

    it 'sends one email per participant of specified status' do
      mailer = double('MaillistMailer')
      allow(MaillistMailer).to receive(:workshop_maillist).and_return(mailer)
      num_participants = @event.attendance('Maybe').count
      expect(mailer).to receive(:deliver_now!).exactly(num_participants).times

      @maillist.send_message

      expect(MaillistMailer).to have_received(:workshop_maillist)
                                  .exactly(num_participants).times
    end
  end
end
