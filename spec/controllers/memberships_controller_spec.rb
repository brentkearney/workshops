# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe MembershipsController, type: :controller do

  context 'As an unauthenticated user' do
    before do
      @event = create(:event, future: true)
      @membership = create(:membership, event: @event, role: 'Confirmed')
    end

    describe '#index' do
      it 'redirects to login screen' do
        get :index, params: { event_id: @event.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#show' do
      it 'redirects to login screen' do
        get :show, params: { event_id: @event.id, id: @membership.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#new' do
      it 'responds with redirect to sign_in page' do
        get :new, params: { event_id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#edit' do
      it 'responds with redirect to sign_in page' do
        get :edit, params: { event_id: 1, id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#create' do
      it 'responds with redirect to sign_in page' do
        membership = build(:membership, event: @event)

        post :create, params: { event_id: 1, membership: membership.attributes }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#update' do
      it 'responds with redirect to sign_in page' do
        patch :update, params: { event_id: 1, id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#destroy' do
      it 'responds with redirect to sign_in page' do
        delete :destroy, params: { event_id: 1, id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#invite' do
      before do
        @membership = build(:membership, event: @event)
      end

      it 'GET responds with redirect to sign_in page' do
        get :invite, params: { event_id: 1 }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'POST responds with redirect to sign_in page' do
        post :invite, params: { event_id: @event.id, invite_members_form:
          { "#{@membership.id}": "1" } }

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
        get :index, params: { event_id: 'foo' }

        expect(response).to redirect_to(events_future_path)
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

          post :create, params: { event_id: 'foo', membership: membership.attributes }

          expect(response).to redirect_to(events_future_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#update' do
        it 'responds with redirect and error message' do
          patch :update, params: { event_id: 'foo', id: 1 }

          expect(response).to redirect_to(events_future_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#destroy' do
        it 'responds with redirect and error message' do
          delete :destroy, params: { event_id: 'foo', id: 1 }

          expect(response).to redirect_to(events_future_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#invite' do
        it 'GET responds with redirect and error message' do
          get :invite, params: { event_id: 'foo' }
          expect(response).to redirect_to(events_future_path)
          expect(flash[:error]).to be_present
        end

        it 'POST responds with redirect and error message' do
          post :invite, params: { event_id: 1, invite_members_form:{ "12": "1" }}

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end
    end

    context 'with a valid event id' do
      before do
        @event = create(:event,future: true)
        @membership = create(:membership, event: @event, role: 'Confirmed')
      end

      describe '#index' do
        it 'responds with success code' do
          get :index, params: { event_id: @event.id }

          expect(response).to be_successful
        end

        it 'assigns @memberships to event members' do
          get :index, params: { event_id: @event.id }

          expect(assigns(:memberships)).to eq('Confirmed' => [@membership])
        end

        context 'as role: member' do
          before do
            @user.member!
          end

          it 'does not assign @member_emails' do
            create(:membership, event: @event, attendance: 'Confirmed')

            get :index, params: { event_id: @event.id }

            expect(assigns(:member_emails)).to be_falsey
          end

          it 'does not assign @organizer_emails' do
            create(:membership, event: @event, attendance: 'Confirmed',
                                role: 'Organizer')

            get :index, params: { event_id: @event.id }

            expect(assigns(:organizer_emails)).to be_falsey
          end
        end
      end

      describe '#show' do
        context 'with valid membership' do
          it 'assigns @membership' do
            membership = create(:membership, event: @event)

            get :show, params: { event_id: @event.id, id: membership.id }

            expect(assigns(:membership)).to eq(membership)
          end
        end

        context 'with invalid membership' do
          it 'redirects to event members index with error message' do
            get :show, params: { event_id: @event.id, id: 666 }

            expect(response).to redirect_to(event_memberships_path(@event))
            expect(flash[:error]).to be_present
          end
        end
      end

      describe '#new' do
        it 'assigns @member' do
          get :new, params: { event_id: @event.id }

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          get :new, params: { event_id: @event.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#edit' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          get :edit, params: { event_id: @event.id, id: membership.id }

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          get :edit, params: { event_id: @event.id, id: membership.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#create' do
        it 'assigns @member' do
          membership = build(:membership, event: @event)

          post :create, params: { event_id: @event.id, membership: membership.attributes }

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          membership = build(:membership, event: @event)

          post :create, params: { event_id: @event.id, membership: membership.attributes }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end

      describe '#update' do
        before do
          @event = create(:event, future: true)
          @person = create(:person)
          @membership = create(:membership, event: @event, person: @person)

          @params = {
            event_id: @event.id, id: @membership.id,
            'membership' =>
            { arrival_date: @membership.event.start_date,
              departure_date: @membership.event.end_date,
              own_accommodation: false, has_guest: true, guest_disclaimer: true,
              special_info: '', share_email: true, num_guests: 2,
              'person_attributes' =>
              { salutation: 'Mr.', firstname: 'Bob', lastname: 'Smith',
                gender: 'M', affiliation: 'Foo', department: '', title: '',
                academic_status: 'Professor', phd_year: 1970, id: @person.id,
                email: @person.email, url: '', phone: '123',
                address1: '123 Street', address2: '', address3: '',
                city: 'City', region: 'Region', postal_code: 'XYZ',
                country: 'Dandylion', emergency_contact: '',
                emergency_phone: '', biography: '', research_areas: '' } }
          }
        end

        def allows_person_updates
          person_params = @params['membership']['person_attributes']
          expect(@person.lastname).not_to eq(person_params['lastname'])
          expect(@person.firstname).not_to eq(person_params['firstname'])
          expect(@person.email).not_to eq(person_params['email'])

          patch :update, params: @params

          person = Membership.find(@membership.id).person
          person_params.each do |key, value|
            expect(person.send(key).to_s).to eq(value.to_s)
          end
        end

        def allows_membership_updates
          @membership.arrival_date = @event.start_date
          @membership.departure_date = @event.departure_date
          @membership.save

          mp = @params['membership']
          mp.delete('person_attributes')
          expect(@membership.arrival_date).not_to eq(mp['arrival_date'])
          expect(@membership.departure_date).not_to eq(mp['departure_date'])

          patch :update, params: @params

          member = Membership.find(@membership.id)
          mp.each do |key, value|
            expect(member.send(key).to_s).to eq(value.to_s)
          end
        end

        def allows_hotel_updates
          @params['membership'][:arrival_date] =
            @params['membership'][:arrival_date].strftime('%Y-%m-%d')
          @params['membership'][:departure_date] =
            @params['membership'][:departure_date].strftime('%Y-%m-%d')
          @params['membership']['room'] = 'Forest'
          @params['membership']['billing'] = '$$$'
          @params['membership']['special_info'] = 'special'
          own_accommodation = @membership.own_accommodation
          @params['membership']['own_accommodation'] = !own_accommodation
          guest_before = @params['membership']['has_guest']
          @params['membership']['has_guest'] = !guest_before

          patch :update, params: @params

          membership = Membership.find(@membership.id)
          expect(membership.room).to eq('Forest')
          expect(membership.billing).to eq('$$$')
          expect(membership.has_guest).to eq(!guest_before)
          expect(membership.special_info).to eq('special')
          expect(membership.own_accommodation).to eq(!own_accommodation)
        end

        def disallows_hotel_updates
          @params['membership']['room'] = 'Forest'
          @params['membership']['billing'] = '$$$'
          @params['membership']['special_info'] = 'special'
          own_accommodation = @membership.own_accommodation
          @params['membership']['own_accommodation'] = !own_accommodation
          @params['membership']['has_guest'] = !@membership.has_guest

          patch :update, params: @params

          membership = Membership.find(@membership.id)
          expect(membership.room).not_to eq('Forest')
          expect(membership.billing).to eq(@membership.billing)
          expect(membership.billing).not_to eq('$$$')
          expect(membership.has_guest).to eq(@membership.has_guest)
          expect(membership.special_info).to eq(@membership.special_info)
          expect(membership.special_info).not_to eq('special')
          expect(membership.own_accommodation).to eq(own_accommodation)
        end

        context 'as role: member, updating another member' do
          before do
            @user.member!
          end

          it 'assigns @member' do
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'denies access, redirects with error' do
            patch :update, params: @params

            expect(response).to redirect_to(my_events_path)
            expect(flash[:error]).to eq('Access denied.')
          end
        end

        context 'as role: member, updating herself' do
          before do
            @user.role = :member
            @user.person = @membership.person
            @user.email = @membership.person.email
            @user.skip_reconfirmation!
            @user.save
            @membership.role = 'Participant'
            @membership.save
          end

          it 'assigns @member' do
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            @params['membership']['person_attributes'][:email] = @user.email
            patch :update, params: @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))

            expect(flash[:success]).to eq('Membership successfully updated.')
          end

          it 'updates User email, signs out with flash message' do
            params_email = 'new@email.com'
            @params['membership']['person_attributes'][:email] = params_email
            expect(@user.email).not_to eq(params_email)
            expect(@user.email).to eq(@membership.person.email)

            patch :update, params: @params

            expect(response).to redirect_to(sign_in_path)
            expect(flash[:notice]).to include('Please verify')
            expect(Person.find(@person.id).email).to eq(params_email)
            expect(User.find(@user.id).pending_reconfirmation?).to be_truthy
          end

          it 'allows updating person fields' do
            allows_person_updates
          end

          it 'allows updating travel dates' do
            arrival = (@membership.event.start_date + 1.day).strftime('%Y-%m-%d')
            @params['membership'][:arrival_date] = arrival
            depart = (@membership.event.end_date - 1.day).strftime('%Y-%m-%d')
            @params['membership'][:departure_date] = depart

            patch :update, params: @params

            new_arrival = Membership.find(@membership.id).arrival_date
                                    .strftime('%Y-%m-%d')
            new_depart = Membership.find(@membership.id).departure_date
                                   .strftime('%Y-%m-%d')
            expect(new_arrival).to eq(arrival)
            expect(new_depart).to eq(depart)
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

            patch :update, params: @params

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

          it 'disallows updating hotel & billing details' do
            disallows_hotel_updates
          end
        end

        context 'as role: organizer' do
          before do
            organizer = create(:membership, role: 'Organizer', event: @event)
            @user.role = :member
            @user.person = organizer.person
            @user.save
          end

          it 'assigns @member' do
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, params: @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:success]).to eq('Membership successfully updated.')
          end

          it 'allows updating some person fields' do
            pa = { salutation: 'Mr.', firstname: 'Aleister',
                   lastname: 'Crowley', email: 'aleister@crowley.co.uk',
                   url: 'http://crowley.org', affiliation: 'AC Inc.',
                   department: 'Mysticism', title: 'Protagonist',
                   research_areas: 'pansexualism, mysticism, deviance',
                   biography: 'The Great Beast 666.', id: @person.id }
            @params['membership']['person_attributes'] = pa

            patch :update, params: @params

            p = Membership.find(@membership.id).person
            expect(p.salutation).to eq('Mr.')
            expect(p.firstname).to eq('Aleister')
            expect(p.lastname).to eq('Crowley')
            expect(p.email).to eq('aleister@crowley.co.uk')
            expect(p.url).to eq('http://crowley.org')
            expect(p.affiliation).to eq('AC Inc.')
            expect(p.department).to eq('Mysticism')
            expect(p.title).to eq('Protagonist')
            expect(p.research_areas).to eq('pansexualism, mysticism, deviance')
            expect(p.biography).to eq('The Great Beast 666.')
          end

          it 'disallows updating some personal info' do
            pa = { firstname: 'Aleister', lastname: 'Crowley',
                   email: 'aleister@crowley.co.uk', affiliation: 'AC Inc.',
                   phone: '1234', gender: 'O',
                   academic_status: 'Student', address1: '123 45th Street',
                   address2: 'Unit 67', address3: 'B',
                   city: 'Leeds', region: 'N/A',
                   postal_code: '891011', country: 'United Kingdom',
                   phd_year: '2047', emergency_contact: 'Mom',
                   emergency_phone: '5678', id: @person.id }
            @params['membership']['person_attributes'] = pa
            p1 = Membership.find(@membership.id).person

            patch :update, params: @params

            p2 = Membership.find(@membership.id).person
            expect(p2.phone).to eq(p1.phone)
            expect(p2.gender).to eq(p1.gender)
            expect(p2.academic_status).to eq(p1.academic_status)
            expect(p2.address1).to eq(p1.address1)
            expect(p2.address2).to eq(p1.address2)
            expect(p2.address3).to eq(p1.address3)
            expect(p2.city).to eq(p1.city)
            expect(p2.region).to eq(p1.region)
            expect(p2.postal_code).to eq(p1.postal_code)
            expect(p2.country).to eq(p2.country)
            expect(p2.phd_year).to eq(p1.phd_year)
            expect(p2.emergency_contact).to eq(p1.emergency_contact)
            expect(p2.emergency_phone).to eq(p1.emergency_phone)
          end

          it 'allows updating role' do
            @membership.role = 'Participant'
            @membership.save
            @params['membership']['role'] = 'Backup Participant'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.role).to eq('Backup Participant')
          end

          it 'disallows changing role to an Organizer role' do
            @membership.role = 'Participant'
            @membership.save
            @params['membership']['role'] = 'Organizer'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.role).not_to eq('Organizer')
          end

          it 'disallows changing role from an Organizer role' do
            @membership.role = 'Organizer'
            @membership.save
            @params['membership']['role'] = 'Participant'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.role).not_to eq('Participant')
          end

          it 'allows updating attendance status' do
            @membership.attendance = 'Declined'
            @membership.save
            @params['membership']['attendance'] = 'Confirmed'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.attendance).to eq('Confirmed')
          end

          it 'disallows updating travel dates' do
            @membership.role = 'Participant'
            @membership.arrival_date = @event.start_date
            @membership.departure_date = @event.end_date
            @membership.save
            new_arrival = @event.start_date + 1.day
            @params['membership']['arrival_date'] = new_arrival
            new_departure = @event.end_date - 1.day
            @params['membership']['departure_date'] = new_departure

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.arrival_date).not_to eq(new_arrival)
            expect(updated_member.departure_date).not_to eq(new_departure)
          end

          it 'allows updating organizer notes' do
            @membership.org_notes = ''
            @membership.save
            @params['membership']['org_notes'] = 'Foo'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.org_notes).to eq('Foo')
          end

          it 'disallows updating hotel and billing details' do
            disallows_hotel_updates
          end
        end

        context 'as role: staff, from different location' do
          before do
            @user.role = :staff
            @user.location = 'Elsewhere'
            @user.save
          end

          it 'assigns @member' do
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'denies access, redirects with error' do
            patch :update, params: @params

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
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, params: @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:success]).to eq('Membership successfully updated.')
          end

          it 'allows updating personal info' do
            allows_person_updates
          end

          it 'allows updating membership details' do
            allows_membership_updates
          end

          it 'disallows updating organizer notes' do
            @params['membership']['org_notes'] = 'Notey note note'

            patch :update, params: @params

            member = Membership.find(@membership.id)
            expect(member.org_notes).not_to eq('Notey note note')
          end

          it 'allows editing hotel and billing details' do
            allows_hotel_updates
          end
        end

        context 'as role: admin' do
          before do
            @user.admin!
          end

          it 'assigns @membership' do
            patch :update, params: @params

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'updates membership, redirects with flash message' do
            patch :update, params: @params

            expect(response).to redirect_to(event_membership_path(@event,
                                                                  @membership))
            expect(flash[:success]).to eq('Membership successfully updated.')
          end

          it 'allows updating personal info' do
            allows_person_updates
          end

          it 'allows updating membership details' do
            allows_membership_updates
          end

          it 'allows updating organizer notes' do
            @membership.org_notes = ''
            @membership.save
            @params['membership']['org_notes'] = 'Foo'

            patch :update, params: @params

            updated_member = Membership.find(@membership.id)
            expect(updated_member.org_notes).to eq('Foo')
          end

          it 'allows editing hotel and billing details' do
            allows_hotel_updates
          end
        end
      end

      describe '#destroy' do
        before do
          @membership = create(:membership, event: @event)
        end

        def denies_access
          delete :destroy, params: { event_id: @event.id, id: @membership.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end

        def deletes_membership
          delete :destroy, params: { event_id: @event.id, id: @membership.id }

          expect(response).to redirect_to event_memberships_path(@event)
          expect(flash[:success]).not_to be_blank
        end

        context 'as role: member' do
          before do
            @user.member!
          end

          it 'assigns @member' do
            delete :destroy, params: { event_id: @event.id, id: @membership.id }

            expect(assigns(:membership)).to eq(@membership)
          end

          it 'denies access, redirects with error' do
            denies_access
          end
        end

        context 'as role: organizer' do
          before do
            organizer = create(:membership, role: 'Organizer', event: @event)
            @user.role = :member
            @user.person = organizer.person
            @user.save
          end

          it 'denies access, redirects with error' do
            denies_access
          end
        end

        context 'as role: staff, from different location' do
          before do
            @user.role = :staff
            @user.location = 'Elsewhere'
            @user.save
          end

          it 'denies access, redirects with error' do
            denies_access
          end
        end

        context 'as role: staff, from same location' do
          before do
            @user.role = :staff
            @user.location = @event.location
            @user.save
          end

          it 'deletes membership, redirects with success' do
            deletes_membership
          end
        end

        context 'as role: admin' do
          before do
            @user.admin!
          end

          it 'deletes membership, redirects with success' do
            deletes_membership
          end
        end
      end

      describe '#invite' do
        before do
          @membership = create(:membership, event: @event,
                                       attendance: 'Not Yet Invited')
        end

        def denies_access
          expect(response).to redirect_to(event_memberships_path(@event))
          expect(flash[:error]).to be_present
        end

        def denies_get_access
          get :invite, params: { event_id: @event.id }
          denies_access
        end

        def denies_post_access
          post :invite, params: { event_id: @event.id, invite_members_form:
                    { "#{@membership.id}": "1" } }
          denies_access
        end

        def allows_get_access
          get :invite, params: { event_id: @event.id }
          expect(response).to render_template(:invite)
        end

        def allows_post_access
          member = create(:membership, attendance: 'Not Yet Invited')
          post :invite, params: { event_id: @event.id, invite_members_form:
                    { "#{member.id}": "1" } }

          expect(flash[:success]).to be_present
          expect(Membership.find(member.id).attendance).to eq('Invited')
        end

        context 'as role: member' do
          before do
            @user.member!
          end

          it 'GET redirects with error' do
            denies_get_access
          end

          it 'POST redirects with error' do
            denies_post_access
          end
        end

        context 'as role: organizer' do
          before do
            organizer = create(:membership, role: 'Organizer', event: @event)
            @user.role = :member
            @user.person = organizer.person
            @user.save
          end

          it 'GET renders invite page' do
            allows_get_access
          end

          it 'POST invites member' do
            allows_post_access
          end
        end

        context 'as role: staff, from different location' do
          before do
            @user.role = :staff
            @user.location = 'Elsewhere'
            @user.save
          end

          it 'GET redirects with error' do
            denies_get_access
          end

          it 'POST redirects with error' do
            denies_post_access
          end
        end

        context 'as role: staff, from same location' do
          before do
            @user.role = :staff
            @user.location = @event.location
            @user.save
          end

          it 'GET renders invite page' do
            allows_get_access
          end

          it 'POST invites member' do
            allows_post_access
          end
        end

        context 'as role: admin' do
          before do
            @user.admin!
          end

          it 'GET renders invite page' do
            allows_get_access
          end

          it 'POST invites member' do
            allows_post_access
          end

          it 'does not invite if event is full' do
            @event.max_participants = @event.num_invited_participants
            @event.save

            member = create(:membership, attendance: 'Not Yet Invited')
            post :invite, params: { event_id: @event.id, invite_members_form:
                      { "#{member.id}": "1" } }

            expect(flash[:error]).to be_present
            updated_member = Membership.find(member.id)
            expect(updated_member.attendance).to eq('Not Yet Invited')
          end

          it 'allows invite to full event if invitee is an Obersver' do
            @event.max_participants = @event.num_invited_participants
            @event.save

            member = create(:membership, attendance: 'Not Yet Invited',
                                               role: 'Observer')
            post :invite, params: { event_id: @event.id, invite_members_form:
                      { "#{member.id}": "1" } }

            expect(flash[:success]).to be_present
            updated_member = Membership.find(member.id)
            expect(updated_member.attendance).to eq('Invited')
          end

          it 'does not invite Observer if max_observers is full' do
            @event.max_observers = @event.num_invited_observers
            @event.save

            member = create(:membership, attendance: 'Not Yet Invited',
                                               role: 'Observer')
            post :invite, params: { event_id: @event.id, invite_members_form:
                      { "#{member.id}": "1" } }

            expect(flash[:error]).to be_present
            updated_member = Membership.find(member.id)
            expect(updated_member.attendance).to eq('Not Yet Invited')
          end
        end

      end
    end
  end
end
