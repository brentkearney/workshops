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

  let(:event) { create(:event) }
  let(:status) { 'Undecided' }
  let(:list_params) do
  {
    email: subject,
    event: event,
    group: status,
    destination: params[:to].first,
  }
  end

  before do
    2.times do
      create(:membership, event: event, attendance: status, role: 'Participant')
    end
  end

  it '.initialize' do
    expect(EventMaillist.new(subject, list_params).class).to eq(EventMaillist)
  end

  context '.send_message' do
    before do
      @domain = GetSetting.site_setting('app_url').gsub(/^.+\/\//, '')
      params[:to] = [event.code + '@' + @domain]
      @maillist = EventMaillist.new(subject, list_params)
      @mailer = double('MaillistMailer')
      allow(MaillistMailer).to receive(:workshop_maillist).and_return(@mailer)
    end

    it 'sends one email per participant of specified attendance status' do
      num_participants = event.attendance(status).count
      expect(num_participants).to be > 0
      expect(@mailer).to receive(:deliver_now!).exactly(num_participants).times

      @maillist.send_message

      expect(MaillistMailer).to have_received(:workshop_maillist)
                                  .exactly(num_participants).times
    end

    it 'excludes Backup Participants from Not Yet Invited group' do
      expect(event.memberships.count).to eq(2)
      event.memberships.each do |member|
        member.attendance = 'Not Yet Invited'
        member.save
      end
      member = event.memberships.last
      member.role = 'Backup Participant'
      member.save

      params[:to] = ["#{event.code}-not_yet_invited@#{@domain}"]
      list_params[:group] = 'Not Yet Invited'

      maillist = EventMaillist.new(subject, list_params)
      mailer = double('MaillistMailer')
      allow(MaillistMailer).to receive(:workshop_maillist).and_return(mailer)
      expect(mailer).to receive(:deliver_now!).exactly(1).times

      maillist.send_message

      expect(MaillistMailer).to have_received(:workshop_maillist)
                                  .exactly(1).times
    end

    it 'sends to organizers if "orgs" group is specified' do
      member = event.memberships.first
      member.role = 'Organizer'
      member.save
      expect(event.organizers.count).to eq(1)
      list_params[:group] = 'orgs'

      maillist = EventMaillist.new(subject, list_params)
      mailer = double('MaillistMailer')
      allow(MaillistMailer).to receive(:workshop_maillist).and_return(mailer)
      expect(mailer).to receive(:deliver_now!).exactly(1).times

      maillist.send_message

      expect(MaillistMailer).to have_received(:workshop_maillist)
                                  .exactly(1).times
    end

    it '"all" group sends to Confirmed, Invited, and Undecided members' do
      event2 = create(:event_with_members)
      member_count = event2.attendance('Confirmed').count +
        event2.attendance('Invited').count +
        event2.attendance('Undecided').count

      list_params[:event] = event2
      list_params[:group] = 'all'

      maillist = EventMaillist.new(subject, list_params)
      mailer = double('MaillistMailer')
      allow(MaillistMailer).to receive(:workshop_maillist).and_return(mailer)
      expect(mailer).to receive(:deliver_now!).exactly(member_count).times

      maillist.send_message

      expect(MaillistMailer).to have_received(:workshop_maillist)
                                  .exactly(member_count).times
    end
  end
end
