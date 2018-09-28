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
    Date: DateTime.current
  }
  end

  subject { Griddler::Email.new(params) }

  before do
    @event = create(:event)
    @person = create(:person)
    @membership = create(:membership, event: @event)
  end

  it '.initialize' do
    expect(EmailProcessor.new(subject).class).to eq(EmailProcessor)
  end

  context 'validates recipient' do
    it 'sends bounce email if recipient is not an event code' do
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(Griddler::Email.new(params)).process
      expect(EmailInvalidCodeBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if recipient is an event code but not an event' do
      params[:to] = ["13w5001@example.com"]
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(Griddler::Email.new(params)).process
      expect(EmailInvalidCodeBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if recipient event code is a real event' do
      params[:to] = ["#{@event.code}@example.com"]
      email = Griddler::Email.new(params)
      allow(EmailInvalidCodeBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailInvalidCodeBounceJob).not_to have_received(:perform_later)
    end
  end

  context 'validates sender' do
    before do
      params[:to] = ["#{@event.code}@example.com"]
    end

    it 'sends bounce email if sender has no Person record' do
      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if sender is not an event member' do
      params[:from] = "#{@person.name} <#{@person.email}>"
      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'sends bounce email if sender is a non-confirmed member of event' do
      @membership.person = @person
      @membership.attendance = 'Not Yet Invited'
      @membership.save

      email = Griddler::Email.new(params)
      allow(EmailFromNonmemberBounceJob).to receive(:perform_later)
      EmailProcessor.new(email).process
      expect(EmailFromNonmemberBounceJob).to have_received(:perform_later)
    end

    it 'does not bounce email if sender is a confirmed member of the event' do
      params[:from] = "#{@person.name} <#{@person.email}>"
      @membership.person = @person
      @membership.attendance = 'Confirmed'
      @membership.save

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
    it 'invokes EventMaillist if sender and recipient are valid' do
      @membership.person = @person
      @membership.attendance = 'Confirmed'
      @membership.save

      params[:from] = "#{@person.name} <#{@person.email}>"
      params[:to] = ["#{@event.code}@example.com"]
      email = Griddler::Email.new(params)

      maillist = double('EventMaillist')
      expect(maillist).to receive(:send_message)
      allow(EventMaillist).to receive(:new).and_return(maillist)

      EmailProcessor.new(email).process
      expect(EventMaillist).to have_received(:new).with(email)
    end
  end
end
