# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class MembershipsController < ApplicationController
  before_action :set_membership, only: [:show, :edit, :update, :destroy, :invite]
  before_action :set_event, :set_attendance
  before_filter :authenticate_user! #, :except => [:index, :show]


  # GET /events/:event_id/memberships
  # GET /events/:event_id/memberships.json
  def index
    @memberships = @event.memberships
    @user_membership = @memberships.select {|m| m.person_id == current_user.person_id }.first
    @pending_invites = @memberships.select {|m| m.is_org? && m.sent_invitation == false }.size > 0

    if policy(@event).use_email_addresses?
      @member_emails = Array.new
      @organizer_emails = Array.new
      @memberships.each do |m|
        @member_emails << "\"#{m.person.name}\" <#{m.person.email}>" if m.attendance == 'Confirmed'
        @organizer_emails << "\"#{m.person.name}\" <#{m.person.email}>" if m.role =~ /Organizer/
      end
    end
  end

  # GET /events/:event_id/memberships/1
  # GET /events/:event_id/memberships/1.json
  def show
  end

  # GET /events/:event_id/memberships/new
  def new
    @membership = Membership.new
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
        format.html { redirect_to @membership, notice: 'Membership was successfully created.' }
        format.json { render :show, status: :created, location: @membership }
      else
        format.html { render :new }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/:event_id/memberships/1
  # PATCH/PUT /events/:event_id/memberships/1.json
  def update
    authorize @membership
    respond_to do |format|
      if @membership.update(membership_params)
        format.html { redirect_to @membership, notice: 'Membership was successfully updated.' }
        format.json { render :show, status: :ok, location: @membership }
      else
        format.html { render :edit }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/:event_id/memberships/1
  # DELETE /events/:event_id/memberships/1.json
  def destroy
    authorize @membership
    @membership.destroy
    respond_to do |format|
      format.html { redirect_to memberships_url, notice: 'Membership was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # PUT /events/:event_id/memberships/invite/1
  def invite
    authorize @membership

    # Temporary hack to get organizer invites sent out NOW; a new custom mailer class is needed.
    # See: https://github.com/scambra/devise_invitable/wiki/Customizing-for-different-Invite-use-cases-(emails-etc.)
    # and: http://stackoverflow.com/questions/21446631/changed-devise-mailer-template-path-now-devise-invitables-e-mail-subject-lines
    # and: https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb
    person = @membership.person
    if person.user.nil?
      new_user = User.new(email: person.email, person: person)
      new_user.skip_confirmation!
      new_user.save
    end
    person.user.invite!
    @membership.sent_invitation = true
    @membership.updated_by = current_user.person.name
    @membership.save
    redirect_to event_memberships_path(@event)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_membership
      @membership = Membership.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def membership_params
      params.require(:membership).permit(:event_id, :person_id, :arrival_date, :departure_date, :role, :attendance, :replied_at, :updated_by, :share_email)
    end
end
