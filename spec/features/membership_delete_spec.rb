# ./spec/features/membership_delete_spec.rb
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership#delete', type: :feature do
  before do
    @event = create(:event_with_members)
    @organizer = @event.memberships.where("role='Contact Organizer'").first
    @participant = @event.memberships.where("role='Participant'").first
    @participant_user = create(:user, email: @participant.person.email,
                                      person: @participant.person)
    @non_member_user = create(:user)
    @other_person = create(:person)
  end

  after(:each) do
    Warden.test_reset!
  end


  def denies_user_access(member)
    expect(page.body).to have_css('div.alert.flash')
    expect(Membership.find_by_id(member.id)).not_to be_nil
    expect(current_path).to eq(event_membership_path(@event, member))
  end

  def allows_delete(member)
    visit event_membership_path(@event, member)
    click_link 'Delete Membership'

    expect(Membership.find_by_id(member.id)).to be_nil
    expect(current_path).to eq(event_memberships_path)
  end

  context 'As a logged-in user who is not a member of the event' do
    it 'does not show delete button' do
      login_as @non_member_user, scope: :user

      visit event_membership_path(@event, @participant)

      expect(page).not_to have_link('Delete Membership')
    end
  end

  context "As a member of the event editing someone else's record" do
    it 'does not show delete button' do
      login_as @participant_user, scope: :user
      member = @event.memberships.where("role='Participant'").last
      expect(member.id).not_to eq(@participant.id)

      visit event_membership_path(@event, @participant)

      expect(page).not_to have_link('Delete Membership')
    end
  end

  context 'As a member of the event editing their own record' do
    it 'does not show delete button' do
      login_as @participant_user, scope: :user

      visit event_membership_path(@event, @participant)

      expect(page).not_to have_link('Delete Membership')
    end
  end

  context 'As an organizer of the event' do
    it 'allows membership deletion' do
      organizer_user = create(:user, email: @organizer.person.email,
                                    person: @organizer.person)
      login_as organizer_user, scope: :user

      # need extra JS tests to get around data-confirm
      #allows_delete(@participant)
    end
  end
end
