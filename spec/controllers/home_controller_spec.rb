# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe HomeController, type: :controller do

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
          @pe = create(:event, past: true)
          @ce = create(:event, current: true)
          @fe = create(:event, future: true)
          @membership = create(:membership, person: person, event: @ce, role: 'Participant')
        end

        it 'responds with success code' do
          get :index

          expect(response).to be_successful
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

        it 'redirects to events_future_path if user has no memberships' do
          person.memberships.delete_all

          get :index

          expect(response).to redirect_to(events_future_path)
        end

        it 'excludes past events from memberships list' do
          person.memberships.delete_all
          create(:membership, person: person, event: @pe)
          current_membership = create(:membership, person: person, event: @ce)
          future_membership = create(:membership, person: person, event: @fe)

          get :index

          expect(assigns(:memberships)).to match_array([current_membership, future_membership])
        end


        context 'role="Participant"' do
          before :each do
            person.memberships.delete_all
          end

          it 'excludes from @memberships where attendance="Declined"' do
            create(:membership, person: person, event: @ce, attendance: 'Declined', role: 'Participant')
            confirmed_membership = create(:membership, person: person, event: @fe, attendance: 'Confirmed', role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([confirmed_membership])
          end

          it 'excludes from @memberships where attendance="Not Yet Invited"' do
            nyi_membership = create(:membership, person: person, event: @fe, attendance: 'Not Yet Invited', role: 'Participant')
            confirmed_membership = create(:membership, person: person, event: @ce, attendance: 'Confirmed', role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([confirmed_membership])
          end
        end

        context 'role="Backup Participant"' do
          it 'excludes from @memberships' do
            person.memberships.delete_all
            create(:membership, person: person, event: @fe, role: 'Backup Participant')
            participant_membership = create(:membership, person: person, event: @ce, role: 'Participant')

            get :index

            expect(assigns(:memberships)).to match_array([participant_membership])
          end
        end

        context 'role="Observer"' do
          before :each do
            person.memberships.delete_all
          end

          it 'excludes from @memberships where attendance="Declined"' do
            create(:membership, person: person, event: @fe, attendance: 'Declined', role: 'Observer')
            confirmed_membership = create(:membership, person: person, event: @ce, attendance: 'Confirmed', role: 'Observer')

            get :index

            expect(assigns(:memberships)).to match_array([confirmed_membership])
          end

          it 'excludes from @memberships where attendance="Not Yet Invited"' do
            create(:membership, person: person, event: @fe, attendance: 'Not Yet Invited', role: 'Observer')
            confirmed_membership = create(:membership, person: person, event: @ce, attendance: 'Confirmed', role: 'Observer')

            get :index

            expect(assigns(:memberships)).to match_array([confirmed_membership])
          end
        end

        context 'role="Organizer" or "Contact Organizer"' do
          before :each do
            person.memberships.delete_all
          end

          it 'excludes events older than 2 weeks ago in @memberships' do
            recent_event = create(:event, start_date: 1.week.ago.beginning_of_week(:sunday),
                              end_date: 1.week.ago.beginning_of_week(:sunday) + 5.days)
            recent_membership = create(:membership, event: recent_event, person: person)
            create(:membership, event: @pe, person: person) # last year

            get :index

            expect(assigns(:memberships)).to match_array([recent_membership])
          end

          it 'includes in @memberships where attendance="[Declined|Not Yet Invited]" for Contact Organizers' do
            declined_membership = create(:membership, person: person, event: @ce, attendance: 'Declined', role: 'Contact Organizer')
            nyi_membership = create(:membership, person: person, event: @fe, attendance: 'Not Yet Invited', role: 'Contact Organizer')

            get :index

            expect(assigns(:memberships)).to match_array([declined_membership, nyi_membership])
          end

          it 'includes in @memberships where attendance="[Declined|Not Yet Invited]" for Organizers' do
            declined_membership = create(:membership, person: person, event: @ce, attendance: 'Declined', role: 'Organizer')
            nyi_membership = create(:membership, person: person, event: @fe, attendance: 'Not Yet Invited', role: 'Organizer')

            get :index

            expect(assigns(:memberships)).to match_array([declined_membership, nyi_membership])
          end
        end
      end

      context ':staff' do
          it 'redirects to future events at user location' do
            user.role = :staff
            user.location = 'EO'
            user.save

            get :index

            expect(response).to redirect_to(events_future_path(user.location))
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
