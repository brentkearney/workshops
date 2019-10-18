# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe RsvpController, type: :controller do
  before do
    @invitation = create(:invitation)
    @membership = @invitation.membership
    @membership.attendance = 'Invited'
    @membership.save
    allow_any_instance_of(LegacyConnector).to receive(:update_member)
  end

  describe 'GET #index' do
    context 'without one-time-password (OTP) in the url' do
      it 'redirects to new invitations page' do
        get :index
        expect(response).to redirect_to(invitations_new_path)
      end
    end

    context 'with a valid OTP in the url' do
      it 'validates the OTP via local db and renders index' do
        get :index, params: { otp: @invitation.code }

        expect(assigns(:invitation)).to eq(@invitation)
        expect(response).to render_template(:index)
      end

      it 'validates the OTP via legacy db' do
        allow_any_instance_of(InvitationChecker).to receive(:check_legacy_database).and_return(@invitation)

        get :index, params: { otp: '123' }

        expect(assigns(:invitation)).to eq(@invitation)
        expect(response).to render_template(:index)
      end
    end

    context 'with an invalid OTP in the url' do
      it 'sets error message' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        allow(lc).to receive(:check_rsvp).with('123').and_return(lc.invalid_otp)

        get :index, params: { otp: '123' }

        expect(assigns(:invitation)).to be_a(InvitationChecker)
        expect(response).to render_template("rsvp/_invitation_errors")
      end
    end
  end

  describe 'GET #no' do
    it 'renders no template' do
      get :no, params: { otp: @invitation.code }
      expect(response).to render_template(:no)
    end
  end

  describe 'POST #no' do
    it 'changes membership attendance to Declined' do
      post :no, params: { otp: @invitation.code, organizer_message: 'Hi' }

      expect(Membership.find(@membership.id).attendance).to eq('Declined')
    end

    it 'forwards to feedback form' do
      post :no, params: { otp: @invitation.code, organizer_message: 'Hi' }

      expect(response).to redirect_to(rsvp_feedback_path(@membership.id))
    end

    it 'with an invalid OTP, it forwards to rsvp_otp' do
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive(:new).and_return(lc)
      allow(lc).to receive(:check_rsvp).with('foo').and_return(lc.invalid_otp)

      post :no, params: { otp: 'foo' }

      expect(response).to redirect_to(rsvp_otp_path('foo'))
    end
  end

  describe 'GET #maybe' do
    it 'renders maybe template' do
      get :maybe, params: { otp: @invitation.code }
      expect(response).to render_template(:maybe)
    end
  end

  describe 'POST #maybe' do
    it 'changes membership attendance to Undecided' do
      post :maybe, params: { otp: @invitation.code, organizer_message: 'Hi' }

      expect(Membership.find(@membership.id).attendance).to eq('Undecided')
    end

    it 'forwards to feedback form' do
      post :maybe, params: { otp: @invitation.code, organizer_message: 'Hi' }

      expect(response).to redirect_to(rsvp_feedback_path(@membership.id))
    end

    it 'with an invalid OTP, it forwards to rsvp_otp' do
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive(:new).and_return(lc)
      allow(lc).to receive(:check_rsvp).with('foo').and_return(lc.invalid_otp)

      post :maybe, params: { otp: 'foo' }

      expect(response).to redirect_to(rsvp_otp_path('foo'))
    end
  end

  describe 'GET #email' do
    before do
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive(:new).and_return(lc)
    end

    it 'renders email template' do
      get :email, params: { otp: @invitation.code }
      expect(response).to render_template(:email)
    end

    it 'assigns person variable' do
      get :email, params: { otp: @invitation.code }
      expect(assigns(:person)).to eq(@invitation.membership.person)
    end
  end

  describe 'POST #email' do
    context 'invalid email' do
      it 'renders validation errors on invalid email submission' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        post :email, params: { otp: @invitation.code, 'email_form' =>
                                    {'person' => { email: 'foo' }}}
        expect(response).to render_template(:email)
        expect(response).to render_template("rsvp/_validation_errors")
      end
    end

    context 'valid email' do
      before do
        @invitation = create(:invitation)
        @email_params = { otp: @invitation.code, 'email_form' =>
                            {'person' => { email: 'foo@bar.com' }}}
      end

      it 'changes participants email & forwards to #yes' do
        post :email, params: @email_params
        person_id = @invitation.membership.person_id
        expect(Person.find(person_id).email).to eq('foo@bar.com')
        expect(response).to redirect_to(rsvp_yes_path(otp: @invitation.code))
      end

      it 'renders confirm_email form if email is held by another record' do
        person = @invitation.membership.person
        person.email = 'mail@example.com'
        person.save
        other_person = create(:person, email: 'foo@bar.com')

        post :email, params: @email_params

        expect(response).to render_template(:confirm_email)
      end
    end
  end

  describe 'POST #confirm_email' do
    def other_person
      Person.find_by_email('foo@bar.com') ||
        create(:person, email: 'foo@bar.com')
    end

    before do
      ConfirmEmailChange.destroy_all
      @email_params = { otp: @invitation.code, 'email_form' =>
                            {'person' => { email: 'foo@bar.com' }}}
      @person = @invitation.membership.person
      @person.email = 'mail@example.com'
      @person.save

      @other_person = other_person
      post :email, params: @email_params
    end

    it 'sets person variable' do
      expect(assigns(:person)).to eq(@person)
    end

    it 'validates confirmation codes' do
      confirm_params = { otp: @invitation.code, 'email_form' =>
                          { person_id: @person.id, replace_email_code: '123',
                            replace_with_email_code: '456'}}
      post :confirm_email, params: confirm_params

      expect(response).to render_template(:confirm_email)
      expect(response).to render_template("rsvp/_validation_errors")
    end

    context 'valid confirmation codes' do
      before do
        @membership = @person.memberships.first
        confirm = ConfirmEmailChange.where(replace_person_id: @person.id).first
        replace_code = confirm.replace_code
        replace_with_code = confirm.replace_with_code

        confirm_params = { otp: @invitation.code, 'email_form' =>
                            { person_id: @person.id,
                              replace_email_code: replace_code,
                              replace_with_email_code: replace_with_code }}
        post :confirm_email, params: confirm_params
      end

      it "adds person's memberships to other person" do
        expect(@other_person.memberships).to include(@membership)
      end

      it 'destroys person record' do
        expect(Person.find_by_id(@person.id)).to be_nil
      end

      it 'redirects to #yes' do
        expect(response).to redirect_to(rsvp_yes_path(otp: @invitation.code))
      end
    end
  end

  describe 'GET #yes' do
    it 'renders yes template' do
      get :yes, params: { otp: @invitation.code }
      expect(response).to render_template(:yes)
    end

    it 'assigns an array of years' do
      get :yes, params: { otp: @invitation.code }
      expect(assigns(:years)).to include(1930..Date.current.year)
    end
  end

  describe 'POST #yes' do
    def yes_params
      {'membership' => { arrival_date: @invitation.membership.event.start_date,
          departure_date: @invitation.membership.event.end_date,
          own_accommodation: false, has_guest: true, guest_disclaimer: true,
          special_info: '', share_email: true },
        'person' => { salutation: 'Mr.', firstname: 'Bob', lastname: 'Smith',
          gender: 'M', affiliation: 'Foo', department: '', title: '',
          academic_status: 'Professor', phd_year: 1970, email: 'foo@bar.com',
           url: '', phone: '123', address1: '123 Street', address2: '',
           address3: '', city: 'City', region: 'Region', postal_code: 'XYZ',
           country: 'Dandylion', emergency_contact: '', emergency_phone: '',
           biography: '', research_areas: ''}
      }
     end

    it 'changes membership attendance to Confirmed' do
      post :yes, params: { otp: @invitation.code, rsvp: yes_params }

      expect(Membership.find(@membership.id).attendance).to eq('Confirmed')
    end

    it 'forwards to feedback form' do
      post :yes, params: { otp: @invitation.code, rsvp: yes_params }

      expect(response).to redirect_to(rsvp_feedback_path(@membership.id))
    end

    it 'with an invalid OTP, it forwards to rsvp_otp' do
      lc = FakeLegacyConnector.new
      allow(LegacyConnector).to receive(:new).and_return(lc)
      expect(lc).to receive(:check_rsvp).with('foo').and_return(lc.invalid_otp)

      post :yes, params: { otp: 'foo', rsvp: yes_params }

      expect(response).to redirect_to(rsvp_otp_path('foo'))
    end
  end

  describe 'GET #feedback' do
    it 'renders feedback template' do
      get :feedback, params: { membership_id: @membership.id }
      expect(response).to render_template(:feedback)
    end
  end

  describe 'POST #feedback' do
    it 'forwards to event memberships page' do
      post :feedback, params: { membership_id: @membership.id, feedback_message: 'Hi' }

      expect(response).to redirect_to(event_memberships_path(@membership.event_id))
    end
  end

  describe 'POST #feedback in production mode' do
    before { allow(Rails.env).to receive(:production?).and_return(true) }

    it 'forwards to event home page' do
      post :feedback, params: { membership_id: @membership.id, feedback_message: 'Hi' }

      expect(response).to redirect_to(@membership.event.url)
    end
  end
end
