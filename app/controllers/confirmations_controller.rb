class ConfirmationsController < Devise::ConfirmationsController

  # GET /confirmations/sent
  def sent; end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message(:success, :confirmed) if is_flashing_format?
      sign_in(resource) # <= THIS LINE ADDED
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      error_msg = resource.errors.full_messages.first
      if error_msg == 'Confirmation token is invalid'
        set_flash_message(:error, :invalid_confirmation_token)
        redirect_to new_user_registration_path
      elsif error_msg == 'Email was already confirmed, please try signing in'
        set_flash_message(:error, :account_already_confirmed)
        redirect_to sign_in_path
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      end
    end
  end

  protected

  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      after_sign_in_path_for(resource)
    else
      new_session_path(resource_name)
    end
  end

end
