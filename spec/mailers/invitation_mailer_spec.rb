# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe InvitationMailer, type: :mailer do
  # Uses SparkPost now

  # def expect_email_was_sent
  #   expect(ActionMailer::Base.deliveries.count).to eq(1)
  # end

  # before :each do
  #   ActionMailer::Base.delivery_method = :test
  #   ActionMailer::Base.perform_deliveries = true
  #   ActionMailer::Base.deliveries = []
  # end

  # after(:each) do
  #   ActionMailer::Base.deliveries.clear
  #   Event.destroy_all
  # end

  # describe '.invite' do
  #   before do
  #     @invitation = create(:invitation)
  #   end

  #   before :each do
  #     InvitationMailer.invite(@invitation).deliver_now
  #     @sent_message = ActionMailer::Base.deliveries.first
  #   end

  #   it 'sends email' do
  #     expect_email_was_sent
  #   end

  #   it 'To: given member' do
  #     expect(@sent_message.to).to include(@invitation.membership.person.email)
  #   end


  #   it "message body includes participant's name" do
  #     expect(@sent_message.body).to have_text(@invitation.membership.person.dear_name)
  #   end

  #   it 'message body includes the invitation code' do
  #     expect(@sent_message.body).to have_text(@invitation.code)
  #   end
  # end
end
