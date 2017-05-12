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
        get :index, { event_id: @event.id }

        expect(response).to be_success
      end

      it 'assigns @memberships to event members' do
        get :index, { event_id: @event.id }

        expect(assigns(:memberships)).to eq({"Confirmed" => [@membership]})
      end
    end

    describe '#show' do
      it 'assigns @membership' do
        get :show, { event_id: @event.id, id: @membership.id }

        expect(assigns(:membership)).to eq(@membership)
      end
    end

    describe '#new' do
      it 'responds with redirect to sign_in page' do
        get :new, { event_id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#edit' do
      it 'responds with redirect to sign_in page' do
        get :edit, { event_id: 1, id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#create' do
      it 'responds with redirect to sign_in page' do
        membership = build(:membership, event: @event)

        post :create, { event_id: 1, membership: membership.attributes }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#update' do
      it 'responds with redirect to sign_in page' do
        patch :update, { event_id: 1, id: 1 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#destroy' do
      it 'responds with redirect to sign_in page' do
        delete :destroy, { event_id: 1, id: 1 }

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
        get :index, { event_id: 'foo' }

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

          post :create, { event_id: 'foo', membership: membership.attributes }

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#update' do
        it 'responds with redirect and error message' do
          patch :update, { event_id: 'foo', id: 1 }

          expect(response).to redirect_to(events_path)
          expect(flash[:error]).to be_present
        end
      end

      describe '#destroy' do
        it 'responds with redirect and error message' do
          delete :destroy, { event_id: 'foo', id: 1 }

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
          get :index, { event_id: @event.id }

          expect(response).to be_success
        end

        it 'assigns @memberships to event members' do
          membership = create(:membership, event: @event, role: 'Confirmed')

          get :index, { event_id: @event.id }

          expect(assigns(:memberships)).to eq({"Confirmed" => [membership]})
        end


        context 'as role: member' do
          before do
            @user.member!
          end

          it 'does not assign @member_emails' do
            confirmed_member = create(:membership, event: @event, attendance: 'Confirmed')

            get :index, { event_id: @event.id }

            expect(assigns(:member_emails)).to be_falsey
          end

          it 'does not assign @organizer_emails' do
            organizer_member = create(:membership, event: @event, attendance: 'Confirmed', role: 'Organizer')

            get :index, { event_id: @event.id }

            expect(assigns(:organizer_emails)).to be_falsey
          end


          context 'as @event organizer' do
            it "assigns @member_emails to confirmed members' emails" do
              organizer_member = create(:membership, event: @event, role: 'Organizer', person: @user.person)
              confirmed_member = create(:membership, event: @event, attendance: 'Confirmed')

              get :index, { event_id: @event.id }

              p1 = organizer_member.person
              p2 = confirmed_member.person
              expect(assigns(:member_emails)).to eq([%Q{"#{p1.name}" <#{p1.email}>}, %Q{"#{p2.name}" <#{p2.email}>}])
            end

            it "assigns @organizer_emails to organizer members' emails" do
              organizer_member = create(:membership, event: @event, role: 'Organizer', person: @user.person)

              get :index, { event_id: @event.id }

              p = organizer_member.person
              expect(assigns(:organizer_emails)).to eq([%Q{"#{p.name}" <#{p.email}>}])
            end
          end
        end


        # For testing staff and admin users
        def has_member_emails
          organizer_member = create(:membership, event: @event, role: 'Organizer')
          confirmed_member = create(:membership, event: @event, attendance: 'Confirmed')

          get :index, { event_id: @event.id }

          p1 = organizer_member.person
          p2 = confirmed_member.person
          expect(assigns(:member_emails)).to eq([%Q{"#{p1.name}" <#{p1.email}>}, %Q{"#{p2.name}" <#{p2.email}>}])
        end

        def has_organizer_emails
          organizer_member = create(:membership, event: @event, role: 'Organizer')

          get :index, { event_id: @event.id }

          p = organizer_member.person
          expect(assigns(:organizer_emails)).to eq([%Q{"#{p.name}" <#{p.email}>}])
        end


        context 'as role: staff' do
          before do
            @user.staff!
          end

          it "assigns @member_emails to confirmed members' emails" do
            has_member_emails
          end

          it "assigns @organizer_emails to organizer members' emails" do
            has_organizer_emails
          end
        end


        context 'as role: admin' do
          before do
            @user.admin!
          end

          it "assigns @member_emails to confirmed members' emails" do
            has_member_emails
          end

          it "assigns @organizer_emails to organizer members' emails" do
            has_organizer_emails
          end
        end


        context 'as role: super_admin' do
          before do
            @user.super_admin!
          end

          it "assigns @member_emails to confirmed members' emails" do
            has_member_emails
          end

          it "assigns @organizer_emails to organizer members' emails" do
            has_organizer_emails
          end
        end
      end


      describe '#show' do
        context 'with valid membership' do
          it 'assigns @membership' do
            membership = create(:membership, event: @event)

            get :show, { event_id: @event.id, id: membership.id }

            expect(assigns(:membership)).to eq(membership)
          end
        end

        context 'with invalid membership' do
          it 'redirects to event members index with error message' do
            get :show, { event_id: @event.id, id: 666 }

            expect(response).to redirect_to(event_memberships_path(@event))
            expect(flash[:error]).to be_present
          end
        end
      end


      describe '#new' do
        it 'assigns @member' do
          get :new, { event_id: @event.id }

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          get :new, { event_id: @event.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end


      describe '#edit' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          get :edit, { event_id: @event.id, id: membership.id }

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          get :edit, { event_id: @event.id, id: membership.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end


      describe '#create' do
        it 'assigns @member' do
          membership = build(:membership, event: @event)

          post :create, { event_id: @event.id, membership: membership.attributes }

          expect(assigns(:membership)).to be_a_new(Membership)
        end

        it 'denies access, redirects with error' do
          membership = build(:membership, event: @event)

          post :create, { event_id: @event.id, membership: membership.attributes }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end


      describe '#update' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          patch :update, { event_id: @event.id, id: membership.id }

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          patch :update, { event_id: @event.id, id: membership.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end


      describe '#destroy' do
        it 'assigns @member' do
          membership = create(:membership, event: @event)

          delete :destroy, { event_id: @event.id, id: membership.id }

          expect(assigns(:membership)).to eq(membership)
        end

        it 'denies access, redirects with error' do
          membership = create(:membership, event: @event)

          delete :destroy, { event_id: @event.id, id: membership.id }

          expect(response).to redirect_to(my_events_path)
          expect(flash[:error]).to eq('Access denied.')
        end
      end
    end
  end
end
