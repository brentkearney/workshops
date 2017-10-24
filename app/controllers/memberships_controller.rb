# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class MembershipsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]
  before_action :set_event
  before_action :set_membership, only: [:show, :edit, :update, :destroy, :invite]

  # GET /events/:event_id/memberships
  # GET /events/:event_id/memberships.json
  def index
    @memberships = SortedMembers.new(@event).memberships
    authorize(Membership.new)
    @current_user = current_user

    # For the "Email Organizers/Participants" buttons
    if policy(@event).use_email_addresses?
      @member_emails = []
      @organizer_emails = []
      @memberships.each do |key, members|
        members.each do |m|
          @member_emails << "\"#{m.person.name}\" <#{m.person.email}>" if m.attendance == 'Confirmed'
          @organizer_emails << "\"#{m.person.name}\" <#{m.person.email}>" if m.role =~ /Organizer/
        end
      end
    end
  end

  # GET /events/:event_id/memberships/1
  # GET /events/:event_id/memberships/1.json
  def show
    authorize @membership
    @person = @membership.person
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
      Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
      form_data = membership_params
      Rails.logger.debug "Permitted params are: #{form_data.inspect}"
      Rails.logger.debug "Membership id is: #{form_data['id']}"
      # Rails.logger.debug "Person id is: #{form_data[person_attributes['id']]}"


      # membership = Membership.find(form_data['id'])
      # membership.assign_attributes(form_data)
      # membership.updated_by = @current_user.name if membership.changed?
      # Rails.logger.debug "Membership is now: #{membership.inspect}"

      # person = Person.find(form_data[person_attributes['id']])
      # person.assign_attributes(form_data)
      # person.updated_by = @current_user.name if person.changed?
      # Rails.logger.debug "Person is now: #{person.inspect}"

      Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"

      if @membership.update(membership_params)
        format.html do
          redirect_to event_membership_path(@event, @membership),
                      notice: 'Membership successfully updated.'
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

  # DELETE /events/:event_id/memberships/1
  # DELETE /events/:event_id/memberships/1.json
  def destroy
    authorize @membership
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
  def set_membership
    @membership = Membership.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to event_memberships_path(@event), error: 'Member not found.'
  end

  def membership_params
    params.require(:membership).permit(
      :id, :event_id, :person_id, :share_email, :role, :attendance,
      :arrival_date, :departure_date, :reviewed, :billing, :room, :has_guest,
      :special_info, :staff_notes, :org_notes,
      person_attributes: [:salutation, :firstname, :lastname, :email, :phone,
                          :gender, :affiliation, :department, :title, :url,
                          :academic_status, :research_areas, :biography, :id]
    )
  end
end
