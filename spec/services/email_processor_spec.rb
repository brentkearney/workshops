# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

# Griddler email processor
describe 'EmailProcessor' do
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

  let(:event) { create(:event) }
  let(:person) { create(:person) }
  let(:membership) { create(:membership, event: event, person: person) }
  # let(:membership) { create(:membership, event: event) }
  let(:organizer) { create(:membership, event: event, role: 'Contact Organizer') }

  it '.initialize' do
    expect(EmailProcessor.new(subject).class).to eq(EmailProcessor)
  end

  context 'validates recipient' do
    it 'sends bounce email if no recipients are event codes' do
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(Griddler::Email.new(params)).process
      expect(EmailInvalidCodeBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if valid code format does not find an event' do
      params[:to] = ["03w5000@example.com"]
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(Griddler::Email.new(params)).process
      expect(EmailInvalidCodeBounceJob).to have_received(:perform_later)
    end

    it 'does not send invalid code bounce if recipient event code is valid' do
      params[:to] = ["#{event.code}@example.com"]
      email = Griddler::Email.new(params)
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailInvalidCodeBounceJob).not_to have_received(:perform_later)
    end

    it 'does not bounce email if at least one of multiple recipients is valid' do
      params[:to] = ['any@example.com', 'thing@example.com', "#{event.code}@example.com"]
      email = Griddler::Email.new(params)
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailInvalidCodeBounceJob).not_to have_received(:perform_later)
    end

    it 'bounces email if none of multiple recipients is valid' do
      params[:to] = ['any@example.com', 'thing@example.com', 'foo@bar.com']
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(Griddler::Email.new(params)).process
      expect(EmailInvalidCodeBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if valid address is in the Cc: field' do
      params.merge!(cc: ["#{event.code}@example.com", 'foo@bar.com'])
      email = Griddler::Email.new(params)
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailInvalidCodeBounceJob).not_to have_received(:perform_later)
    end
  end

  context 'validates sender' do
    before do
      params[:to] = ["#{event.code}@example.com"]
    end

    it 'sends bounce email if sender has no Person record' do
      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if sender is not an event member' do
      params[:from] = "#{person.name} <#{person.email}>"
      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if sender is a non-confirmed member of event' do
      membership.person = person
      membership.attendance = 'Not Yet Invited'
      membership.save

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if sender is a confirmed member of the event' do
      params[:from] = "#{person.name} <#{person.email}>"
      membership.person = person
      membership.attendance = 'Confirmed'
      membership.save

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).not_to have_received(:perform_later)
    end

    it 'sends bounce email if non-organizer sends to unauthorized sub-group' do
      params[:from] = "#{person.name} <#{person.email}>"
      membership.person = person
      membership.attendance = 'Confirmed'
      membership.save
      params[:to] = ["#{event.code}-declined@example.com"]
      email = Griddler::Email.new(params)
      allow(UnauthorizedSubgroupBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(UnauthorizedSubgroupBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if non-organizer sends to authorized sub-group' do
      params[:from] = "#{person.name} <#{person.email}>"
      membership.person = person
      membership.attendance = 'Confirmed'
      membership.save
      params[:to] = ["#{event.code}-all@example.com"]
      email = Griddler::Email.new(params)
      allow(UnauthorizedSubgroupBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(UnauthorizedSubgroupBounceJob).not_to have_received(:perform_later)
    end

    it 'does not bounce email if sender is an organizer, even if Declined' do
      member = organizer
      params[:from] = "#{member.person.name} <#{member.person.email}>"
      member.attendance = 'Declined'
      member.save

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).not_to have_received(:perform_later)
    end

    it 'does not bounce email if sender is a staff user for event.location' do
      staff_person = create(:person)
      create(:user, person: staff_person, role: 'staff', location: event.location)
      params[:from] = %Q("#{staff_person.name}" <#{staff_person.email}>)

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).not_to have_received(:perform_later)
    end

    it 'sends bounce email if sender is staff with location other than event' do
      staff_person = create(:person)
      create(:user, person: staff_person, role: 'staff', location: 'nope')
      params[:from] = %Q("#{staff_person.name}" <#{staff_person.email}>)

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if sender is a admin user, regardless of location' do
      admin_person = create(:person)
      create(:user, person: admin_person, role: 'admin', location: 'nope')
      params[:from] = %Q("#{admin_person.name}" <#{admin_person.email}>)

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).not_to have_received(:perform_later)
    end

    it 'sends report to sysadmin if sender has invalid email address' do
      params[:from] = 'invalid-email@foo'
      email = Griddler::Email.new(params)
      mailer = double('StaffMailer')
      expect(mailer).to receive(:deliver_now)
      allow(StaffMailer).to receive(:notify_sysadmin).and_return(mailer)

      EmailProcessor.new(email).process
      expect(StaffMailer).to have_received(:notify_sysadmin)
    end
  end

  context '.process delivers email to maillist' do
    before do
      maillist = double('EventMaillist')
      expect(maillist).to receive(:send_message).at_least(:once)
      allow(EventMaillist).to receive(:new).and_return(maillist)

      membership.person = person
      membership.attendance = 'Confirmed'
      membership.save
      params[:from] = "#{person.name} <#{person.email}>"
    end

    it 'invokes EventMaillist if sender and recipient are valid' do
      params[:to] = ["#{event.code}@example.com"]
      email = Griddler::Email.new(params)
      list_params = {
        event: event,
        group: 'Confirmed',
        destination: params[:to].first
      }

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).with(email, list_params)
    end

    it 'passes attendance status from recipient email to EventMaillist' do
      params[:to] = ["#{event.code}-not_yet_invited@example.com"]
      params[:from] = organizer.person.email
      email = Griddler::Email.new(params)
      list_params = {
        event: event,
        group: 'Not Yet Invited',
        destination: params[:to].first
      }

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).with(email, list_params)
    end

    it 'passes "orgs" from recipient email to EventMaillist' do
      params[:to] = ["#{event.code}-orgs@example.com"]
      email = Griddler::Email.new(params)
      list_params = {
        event: event,
        destination: params[:to].first,
        group: 'orgs'
      }

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).with(email, list_params)
    end

    it 'passes "all" from recipient email to EventMaillist' do
      params[:to] = ["#{event.code}-all@example.com"]
      email = Griddler::Email.new(params)
      list_params = {
        event: event,
        destination: params[:to].first,
        group: 'all'
      }

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).with(email, list_params)
    end

    it 'invokes EventMaillist once for each event in the To: field' do
      event2 = create(:event)
      create(:membership, event: event2, person: person)
      params[:to] = ["#{event.code}@example.com", "#{event2.code}@example.com"]
      email = Griddler::Email.new(params)

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).exactly(2).times
    end

    it 'invokes EventMaillist once for each event in the Cc: field' do
      event2 = create(:event)
      create(:membership, event: event2, person: person)
      params[:to] = ['myfriend@example.com']
      params[:cc] = ["#{event.code}@example.com", "#{event2.code}@example.com"]
      email = Griddler::Email.new(params)

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).exactly(2).times
    end

    it 'invokes EventMaillist once and EmailFromNonmemberBounceJob once if
      sender is confirmed for one event in To: but not another' do
      event2 = create(:event)
      params[:to] = ["#{event.code}@example.com", "#{event2.code}@example.com"]
      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)

      EmailProcessor.new(email).process

      expect(EventMaillist).to have_received(:new).exactly(1).times
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later).exactly(1).times
    end
  end
end
