# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe MembershipsController, type: :controller do

  context 'As an unauthenticated user' do
    before do
      @event = create(:event)
      @membership = create(:membership, event: @event, role: 'Confirmed')
    end

    describe '#index' do
      it 'responds with success code' do
        get :index, event_id: @event.id

        expect(response).to be_success
      end

      it 'assigns @memberships to event members' do
        get :index, event_id: @event.id

        expect(assigns(:memberships)).to eq('Confirmed' => [@membership])
      end
    end

    describe '#show' do
      it 'assigns @membership' do
        get :show, event_id: @event.id, id: @membership.id

        expect(assigns(:membership)).to eq(@membership)
      end
    end

    describe '#new' do
      it 'responds with redirect to sign_in page' do
        get :new, event_id: 1

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#edit' do
      it 'responds with redirect to sign_in page' do
        get :edit, event_id: 1, id: 1

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#create' do
      it 'responds with redirect to sign_in page' do
        membership = build(:membership, event: @event)

        post :create, event_id: 1, membership: membership.attributes

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#update' do
      it 'responds with redirect to sign_in page' do
        patch :update, event_id: 1, id: 1

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#destroy' do
      it 'responds with redirect to sign_in page' do
        delete :destroy, event_id: 1, id: 1

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'As an authenticated user' do
    before do
      @user = create(:user, person: build(:person), role: 'member')
      allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
      allow(controller).to receive(:current_user).and_return(@user)
    end

    context 'with invalid event id' do
      def redirects_with_error
        get :index, event_id: 'foo'

        expect(response).to redirect_to(events_path)
        expect(flash[:error]).to be_present
      end

      describe '#index' do
        it 'responds with redirect and error message' do
          redirects_with_error
        end
      end

      describe '#show' do
        it 'responds with redirect and error message' do
          redirects_with_error
        end
      end

      describe '#new' do
        it 'responds with redirect and error message' do
          redirects_with_error
        end
      end

      describe '#edit' do
        it 'responds with redirect and error message' do
          redirects_with_error
        end
      end

      describe '#create' do
        it 'responds with redirect and error message' do
          membership = build(:membership, event: @event)

          post :create, event_id: 'foo', membership: membership.attributes

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#update' do
        it 'responds with redirect and error message' do
          patch :update, event_id: 'foo', id: 1

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#destroy' do
        it 'responds with redirect and error message' do
          delete :destroy, event_id: 'foo', id: 1

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end
    end

    context 'with a valid event id' do
      before do
        @event = create(:event)
      end

      after :each do
        @event.memberships.destroy_all
      end

      describe '#index' do
        it 'responds with success code' do
          get :index, event_id: @event.id

          expect(response).to be_success
        end

        it 'assigns @memberships to event members' do
          membership = create(:membership, event: @event, role: 'Confirmed')

          get :index, event_id: @event.id

          expect(assigns(:memberships)).to eq('Confirmed' => [membership])
        end

        context 'as role: member' do
          before do
            @user.member!
          end

          it 'does not assign @member_emails' do
            create(:membership, event: @event, attendance: 'Confirmed')

            get :index, event_id: @event.id

            expect(assigns(:member_emails)).to be_falsey
          end

          it 'does not assign @organizer_emails' do
            create(:membership, event: @event, attendance: 'Confirmed',
                                role: 'Organizer')

            get :index, event_id: @event.id

            expect(assigns(:organizer_emails)).to be_falsey
          end

          context 'as @event organizer' do
            it "assigns @member_emails to confirmed members' emails" do
              organizer_member = create(:membership, event: @event,
                                                     role: 'Organizer',
                                                     person: @user.person)
              confirmed_member = create(:membership, event: @event,
                                                     attendance: 'Confirmed')

              get :index, event_id: @event.id

              p1 = organizer_member.person
              p2 = confirmed_member.person
              members = [%("#{p1.name}" <#{p1.email}>),
                         %("#{p2.name}" <#{p2.email}>)]
              expect(assigns(:member_emails)).to eq(members)
            end

            it "assigns @organizer_emails to organizer members' emails" do
              organizer_member = create(:membership, event: @event,
                                                     role: 'Organizer',
                                                     person: @user.person)

              get :index, event_id: @event.id

              p = organizer_member.person
              member = [%("#{p.name}" <#{p.email}>)]
              expect(assigns(:organizer_emails)).to eq(member)
            end
          end
        end

        # For testing staff and admin users
        def member_emails?
          organizer_member = create(:membership, event: @event,
                                                 role: 'Organizer')
          confirmed_member = create(:membership, event: @event,
                                                 attendance: 'Confirmed')

          get :index, event_id: @event.id

          p1 = organizer_member.person
          p2 = confirmed_member.person
          members = [%("#{p1.name}" <#{p1.email}>),
                     %("#{p2.name}" <#{p2.email}>)]
          expect(assigns(:member_emails)).to eq(members)
        end

        def organizer_emails?
          organizer_member = create(:membership, event: @event,
                                                 role: 'Organizer')
          get :index, event_id: @event.id

          p = organizer_member.person
          member = [%("#{p.name}" <#{p.email}>)]
          expect(assigns(:organizer_emails)).to eq(member)
        end

        context 'as role: staff' do
          before do
            @user.staff!
          end

          it "assigns @member_emails to confirmed members' emails" do
            member_emails?
          end

          it "assigns @organizer_emails to organizer members' emails" do
            organizer_emails?
          end
        end

        context 'as role: admin' do
          before do
            @user.admin!
          end

          it "assigns @member_emails to confirmed members' emails" do
            member_emails?
          end

          it "assigns @organizer_emails to organizer members' emails" do
            organizer_emails?
          end
        end

        context 'as role: super_admin' do
          before do
            @user.super_admin!
          end

          it "assigns @member_emails to confirmed members' emails" do
            member_emails?
          end

          it "assigns @organizer_emails to organizer members' emails" do
            organizer_emails?
          end
        end
      end

      describe '#show' do
        context 'with valid membership' do
          it 'assigns @membership' do
            membership = create(:membership, event: @event)

            get :show, event_id: @event.id, id: membership.id

            expect(assigns(:membership)).to eq(membership)
          end
        end

        context 'with invalid membership' do
          it 'redirects to event members index with error message' do
            get :show, event_id: @event.id, id: 666

            expect(response).to redirect_to(event_memberships_path(@event))
            expect(flash[:error]).to be_present
          end
        end
      end

      describe '#new' do
        it 'assigns @member' do
          get :new, event_id: @event.id

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          get :new, event_id: @event.id

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#edit' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          get :edit, event_id: @event.id, id: membership.id

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          get :edit, event_id: @event.id, id: membership.id

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#create' do
        it 'assigns @member' do
          membership = build(:membership, event: @event)

          post :create, event_id: @event.id, membership: membership.attributes

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          membership = build(:membership, event: @event)

          post :create, event_id: @event.id, membership: membership.attributes

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#update' do
        before do
          @event = create(:event)
          @person = create(:person)
          @membership = create(:membership, event: @event, person: @person)
          @params = {
            'event_id' => @event.id,
            'id' => @membership.id,
            'membership' =>
            { arrival_date: @membership.event.start_date,
              departure_date: @membership.event.end_date,
              own_accommodation: false, has_guest: true, guest_disclaimer: true,
              special_info: '', share_email: true,
            'person_attributes' =>
              { salutation: 'Mr.', firstname: 'Bob', lastname: 'Smith',
                gender: 'M', affiliation: 'Foo', department: '', title: '',
                academic_status: 'Professor', phd_year: 1970, email: 'foo@bar.com',
                url: '', phone: '123', address1: '123 Street', address2: '',
                address3: '', city: 'City', region: 'Region', postal_code: 'XYZ',
                country: 'Dandylion', emergency_contact: '', emergency_phone: '',
                biography: '', research_areas: '' }
            }
          }
        end

        context 'as role: member, updating another member' do
          before do
            @user.member!
          end

          it 'assigns @member' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'denies access, redirects with error' do
            patch :update, @params

            expect(response).to redirect_to(my_events_path)
            expect(flash[:error]).to eq('Access denied.')
          end
        end

        context 'as role: member, updating herself' do
          before do
            @user.member!
            @membership.role = 'Participant'
            @membership.person_id = @user.person_id
            @membership.save
          end

          it 'assigns @member' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:notice]).to eq('Membership successfully updated.')
          end

          it 'allows updating travel dates' do
            arrival = @membership.event.start_date + 1.day
            @params['membership']['arrival_date'] = arrival
            depart = @membership.event.end_date - 1.day
            @params['membership']['departure_date'] = depart

            patch :update, @params

            expect(Membership.find(@membership.id).arrival_date).to eq(arrival)
            expect(Membership.find(@membership.id).departure_date).to eq(depart)
          end

          it 'disallows updating other membership details' do
            role = @membership.role
            @params['membership']['role'] = 'Organizer'
            reviewed = @membership.reviewed
            @params['membership']['reviewed'] = false
            attendance = @membership.attendance
            @params['membership']['attendance'] = 'Declined'
            @params['membership']['staff_notes'] = 'Foo'
            @params['membership']['org_notes'] = 'Bar'

            patch :update, @params

            membership = Membership.find(@membership.id)
            expect(membership.role).to eq(role)
            expect(membership.role).not_to eq('Organizer')
            expect(membership.reviewed).to eq(reviewed)
            expect(membership.reviewed).not_to eq(false)
            expect(membership.attendance).to eq(attendance)
            expect(membership.attendance).not_to eq('Declined')
            expect(membership.staff_notes).not_to eq('Foo')
            expect(membership.org_notes).not_to eq('Bar')

          end

          it 'disallows updating other hotel & billing details' do
            @params['membership']['room'] = 'Forest'
            billing = @membership.billing
            @params['membership']['billing'] = '$$$'
            special_info = @membership.special_info
            @params['membership']['special_info'] = 'special'
            own_accommodation = @membership.own_accommodation
            @params['membership']['own_accommodation'] = !own_accommodation
            has_guest = @membership.has_guest
            @params['membership']['has_guest'] = !has_guest
            guest_disclaimer = @membership.guest_disclaimer
            @params['membership']['guest_disclaimer'] = false

            patch :update, @params

            membership = Membership.find(@membership.id)
            expect(membership.room).not_to eq('Forest')
            expect(membership.billing).to eq(billing)
            expect(membership.billing).not_to eq('$$$')
            expect(membership.has_guest).to eq(has_guest)
            expect(membership.special_info).to eq(special_info)
            expect(membership.special_info).not_to eq('special')
            expect(membership.own_accommodation).to eq(own_accommodation)
            expect(membership.guest_disclaimer).to eq(guest_disclaimer)
          end
        end

        context 'as role: organizer' do
          before do
            @user.role = :member
            @user.person = @membership.person
            @user.save
            @membership.role = 'Organizer'
            @membership.save
            # create(:membership, role: 'Organizer', person: @user.person,
            #                     event: @event)
          end

          it 'assigns @member' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:notice]).to eq('Membership successfully updated.')
          end

          it 'allows updating person info'
          it 'disallows updating some personal info'
          it 'allows updating role'
          it 'disallows changing role to or from Organizer roles'
          it 'allows updating attendance status'
          it 'disallows updating travel dates'
          it 'allows updating organizer notes'
          it 'disallows updating hotel and billing details'
        end

        context 'as role: staff, from different location' do
          before do
            @user.role = :staff
            @user.location = 'Elsewhere'
            @user.save
          end

          it 'assigns @member' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'denies access, redirects with error' do
            patch :update, @params

            expect(response).to redirect_to(my_events_path)
            expect(flash[:error]).to eq('Access denied.')
          end
        end

        context 'as role: staff, from same location' do
          before do
            @user.role = :staff
            @user.location = @event.location
            @user.save
          end

          it 'assigns @member' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:notice]).to eq('Membership successfully updated.')
          end

          it 'allows updating personal info'
          it 'allows updating membership details'
          it 'disallows updating organizer notes'
          it 'allows editing hotel and billing details'
        end

        context 'as role: admin' do
          before do
            @user.admin!
          end

          it 'assigns @membership' do
            patch :update, @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:notice]).to eq('Membership successfully updated.')
          end

          it 'allows updating personal info'
          it 'allows updating membership details'
          it 'allows updating organizer notes'
          it 'allows editing hotel and billing details'
        end
      end

      describe '#destroy' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          delete :destroy, event_id: @event.id, id: membership.id

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          delete :destroy, event_id: @event.id, id: membership.id

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end
    end
  end
end
