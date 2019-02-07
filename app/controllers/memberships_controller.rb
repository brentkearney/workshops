# ./app/controllers/memberships_controller.rb
# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, :set_user
  before_action :set_membership, except: [:index, :new, :create, :add]

  # GET /events/:event_id/memberships
  # GET /events/:event_id/memberships.json
  def index
    SyncMembers.new(@event) if policy(@event).sync?
    @memberships = SortedMembers.new(@event).memberships
    authorize(Membership.new)
    @domain = GetSetting.email(@event.location, 'email_domain')
    assign_buttons if policy(@event).show_email_buttons?('Confirmed')
  end

  # GET /events/:event_id/memberships/1
  # GET /events/:event_id/memberships/1.json
  def show
    authorize @membership
    @person = @membership.person
    @memberships = other_memberships
  end

  # GET /events/:event_id/memberships/new
  def new
    @membership = Membership.new(event: @event)
    authorize @membership
  end

  # GET /events/:event_id/memberships/add
  # POST /events/:event_id/memberships/add
  def add
    @membership = Membership.new(event: @event)
    authorize @membership
  end

  # GET /events/:event_id/memberships/1/edit
  def edit
    authorize @membership
  end

  # POST /events/:event_id/memberships
  # POST /events/:event_id/memberships.json
  def create
    @membership = Membership.new(membership_params)
    authorize @membership

    respond_to do |format|
      if @membership.save
        format.html do
          redirect_to @membership,
                      notice: 'Membership was successfully created.'
        end
        format.json { render :show, status: :created, location: @membership }
      else
        format.html { render :new }
        format.json do
          render json: @membership.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /events/:event_id/memberships/1
  # PATCH/PUT /events/:event_id/memberships/1.json
  def update
    authorize @membership
    member_params = MembershipParametizer.new(@membership, membership_params,
                                              @current_user)
    respond_to do |format|
      if @membership.update(member_params.data)
        format.html do
          if member_params.verify_email
            redirect_to event_membership_email_change_path(@event, @membership),
              warning: 'Membership updated, but there is an email conflict!'
          elsif member_params.new_user_email?
            sign_out @current_user
            redirect_to sign_in_path, notice: 'Please verify your account by
              clicking the confirmation link that we sent to your new email
              address.'.squish
          else
            redirect_to event_membership_path(@event, @membership),
                        notice: 'Membership successfully updated.'
          end
        end
        format.json do
          render :show, status: :ok,
                        location: event_membership_path(@event, @membership)
        end
      else
        format.html { render :edit }
        format.json do
          render json: @membership.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def email_change
    @confirmation = ConfirmEmailChange.where(replace_with_id:
                                             @membership.person_id).first
    if @confirmation.nil?
      redirect_to event_membership_path(@membership.event, @membership),
        error: 'No email change confirmation record found.' and return
    end
    person = Person.find_by_id(@confirmation.replace_person_id) ||
             @membership.person
    @email_form = EmailForm.new(person)

    if request.post? && @email_form.verify_email_change(confirm_email_params)
      redirect_to event_membership_path(@membership.event, @membership),
        success: 'Email changed and records consolidated!'
    end
  end

  def cancel_email_change
    ConfirmEmailChange.where(replace_with_id: @membership.person_id)
                      .first.delete
    redirect_to event_membership_path(@membership.event, @membership),
        success: 'Email change cancelled.'
  end

  # DELETE /events/:event_id/memberships/1
  # DELETE /events/:event_id/memberships/1.json
  def destroy
    authorize @membership
    @membership.updated_by = @current_user.name
    @membership.destroy

    respond_to do |format|
      format.html do
        redirect_to event_memberships_path(@event),
                    notice: 'Membership was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  def assign_buttons
    organizers = @memberships.values[0].nil? ? '' : select_organizers
    @organizer_emails = map_emails(organizers)
  end

  def map_emails(members)
    return [] if members.blank?
    members.map { |m| "\"#{m.person.name}\" <#{m.person.email}>" }
  end

  def select_organizers
    @memberships.values[0].select { |m| m.role =~ /Organizer/ }
  end

  def other_memberships
    memberships = []
    @membership.person.memberships.includes(:event)
               .order('events.start_date desc').each do |m|
      if m.attendance == 'Not Yet Invited' || m.attendance == 'Declined'
        memberships << m if policy(m).show_details?
      else
        memberships << m
      end
    end
    memberships - [@membership]
  end

  def set_membership
    membership_id = (params[:id] || params[:membership_id]).to_i
    @membership = Membership.find(membership_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to event_memberships_path(@event), error: 'Member not found.'
  end

  def set_user
    @current_user = current_user
  end

  def membership_params
    @membership = Membership.new(event: @event) if @membership.nil?
    allowed_fields = policy(@membership).allowed_fields?
    params.require(:membership).permit(allowed_fields)
  end

  def confirm_email_params
    params.require(:email_form).permit(:person_id, :replace_email_code,
                                       :replace_with_email_code)
  end
end
