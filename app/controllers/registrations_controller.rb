# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RegistrationsController < Devise::RegistrationsController
  def create
    invalid_email_redirect and return unless valid_email?
    person = Person.find_by_email(user_email)
    no_person_redirect and return if person.blank?

    membership = person.memberships.where("(role LIKE '%Org%') OR
          (attendance != 'Not Yet Invited' AND attendance != 'Declined')").first
    not_invited_redirect and return if membership.blank?

    params[:user][:person_id] = person.id
    super
  end


  protected

  def after_inactive_sign_up_path_for(resource)
    confirmation_sent_path
  end

  private

  def not_invited_redirect
    redirect_to register_path, error: 'We have no records of pending event invitations for you. Please contact the event organizer.'
  end

  def no_person_redirect
    redirect_to register_path, error: 'We have no record of that email address. Please check our correspondence with you, to see what email address is in the To: field.'
  end

  def invalid_email_redirect
    redirect_to register_path, error: 'You must enter a valid e-mail address.'
  end

  def sign_up_params
    params.require(:user).permit(:person_id, :email, :password, :password_confirmation)
    rescue_from ActionController::ParameterMissing do |e|
      redirect_to register_path, error: 'There was a problem with your form submission.'
    end
  end

  def account_update_params
    params.require(:user).permit(:person_id, :password, :password_confirmation, :current_password)
  end

  def valid_email?
    EmailValidator.valid?(sign_up_params[:email])
  end

  def user_email
    sign_up_params[:email].downcase
  end
end
