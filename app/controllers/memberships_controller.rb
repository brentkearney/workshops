# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class MembershipsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]
  before_action :set_event, :set_user
  before_action :set_membership, only: [:show, :edit, :update, :destroy, :invite]

  # GET /events/:event_id/memberships
  # GET /events/:event_id/memberships.json
  def index
    @memberships = SortedMembers.new(@event).memberships
    authorize(Membership.new)

    # For the "Email Organizers/Participants" buttons
    assign_buttons if policy(@event).use_email_addresses?
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

    Rails.logger.debug "\n\n*******Parametizer returned: #{member_params.data} **********\n\n"

    respond_to do |format|
      if @membership.update(member_params.data)
        format.html do
          if member_params.new_user_email?
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
        Rails.logger.debug "\n\n*******Errors: #{@membership.errors.messages} **********\n\n"
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

  def assign_buttons
    @member_emails = map_emails(@memberships['Confirmed'])
    organizers = @memberships.values[0].select { |m| m.role =~ /Organizer/ }
    @organizer_emails = map_emails(organizers)
  end

  def map_emails(members)
    members.map { |m| "\"#{m.person.name}\" <#{m.person.email}>" }
  end

  def set_membership
    @membership = Membership.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to event_memberships_path(@event), error: 'Member not found.'
  end

  def set_user
    @current_user = current_user
  end

  def membership_params
    @membership = Membership.new(event: @event) if @membership.nil?
    allowed_fields = policy(@membership).allowed_fields?
    Rails.logger.debug "\n\n************ allowed parameters: #{allowed_fields} **********\n\n"
    params.require(:membership).permit(allowed_fields)
  end
end
