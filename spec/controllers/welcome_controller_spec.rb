# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do

  describe "#index" do
    context 'without authentication' do
      it 'redirects to sign-in page' do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with authentication' do
      let(:person) { build(:person) }
      let(:user) { build(:user, person: person) }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context ':member' do
        before do
          user.member!
          @event = create(:event, start_date: Date.today.next_week.next_week(:sunday),
                          end_date: Date.today.next_week.next_week(:sunday) + 5.days)
          @membership = create(:membership, person: person, event: @event, role: 'Participant')
        end

        it 'responds with success code' do
          get :index

          expect(response).to be_success
        end

        it 'renders :index' do
          get :index

          expect(response).to render_template(:index)
        end

        it 'assigns @heading' do
          get :index

          expect(assigns(:heading)).not_to be_empty
        end

        it "assigns @memberships to user's memberships" do
          get :index

          expect(assigns(:memberships)).to match_array([@membership])
        end

        it 'redirects to my_events_path if user has no memberships' do
          person.memberships.delete_all

          get :index

          expect(response).to redirect_to(my_events_path)
        end

        it 'excludes past events from memberships list' do
          person.memberships.delete_all
          past_event = create(:event, past: true)
          past_membership = create(:membership, person: person, event: past_event)
          current_event = create(:event, current: true)
          current_membership = create(:membership, person: person, event: current_event)
          future_event = create(:event, future: true)
          future_membership = create(:membership, person: person, event: future_event)

          get :index

          expect(assigns(:memberships)).to match_array([current_membership, future_membership])
        end


        context 'role="Participant"' do
          before do
            Event.destroy_all
          end

          it 'excludes from @memberships where attendance="Declined"' do
            @declined_membership = create(:membership, person: person, attendance: 'Declined', role: 'Participant')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([@confirmed_membership])
          end

          it 'excludes from @memberships where attendance="Not Yet Invited"' do
            @nyi_membership = create(:membership, person: person, attendance: 'Not Yet Invited', role: 'Participant')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([@confirmed_membership])
          end
        end

        context 'role="Backup Participant"' do
          before do
            Event.destroy_all
          end

          it 'excludes from @memberships' do
            @backup_membership = create(:membership, person: person, role: 'Backup Participant')
            @participant_membership = create(:membership, person: person, role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([@participant_membership])
          end
        end

        context 'role="Observer"' do
          before do
            Event.destroy_all
          end

          it 'excludes from @memberships where attendance="Declined"' do
            @declined_membership = create(:membership, person: person, attendance: 'Declined', role: 'Observer')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Observer')

            get :index

            expect(assigns(:memberships)).to match_array([@confirmed_membership])
          end

          it 'excludes from @memberships where attendance="Not Yet Invited"' do
            @nyi_membership = create(:membership, person: person, attendance: 'Not Yet Invited', role: 'Observer')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Observer')

            get :index

            expect(assigns(:memberships)).to match_array([@confirmed_membership])
          end
        end

        context 'role="Organizer" or "Contact Organizer"' do
          before do
            Event.destroy_all
          end

          it 'includes in @memberships where attendance="Declined"' do
            @declined_org_membership = create(:membership, person: person, attendance: 'Declined', role: 'Organizer')
            @declined_contact_org_membership = create(:membership, person: person, attendance: 'Declined', role: 'Contact Organizer')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Organizer')

            get :index

            expect(assigns(:memberships)).to match_array([@declined_org_membership, @declined_contact_org_membership, @confirmed_membership])
          end

          it 'includes in @memberships where attendance="Not Yet Invited"' do
            @nyi_org_membership = create(:membership, person: person, attendance: 'Not Yet Invited', role: 'Organizer')
            @nyi_contact_org_membership = create(:membership, person: person, attendance: 'Not Yet Invited', role: 'Contact Organizer')
            @confirmed_membership = create(:membership, person: person, attendance: 'Confirmed', role: 'Organizer')

            get :index

            expect(assigns(:memberships)).to match_array([@nyi_org_membership, @nyi_contact_org_membership, @confirmed_membership])
          end
        end
      end

      context ':staff' do
          it 'redirects to future events' do
            user.staff!

            get :index

            expect(response).to redirect_to(events_future_path)
          end
      end

      context ':admin' do
        it 'redirects to future events' do
          user.admin!

          get :index

          expect(response).to redirect_to(events_future_path)
        end
      end

      context ':super_admin' do
        it 'redirects to future events' do
          user.super_admin!

          get :index

          expect(response).to redirect_to(events_future_path)
        end
      end
    end
  end
end