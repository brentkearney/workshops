# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_user!
    before_action :authorize_access

    def authorize_access
      unless current_user.is_staff?
        redirect_to root_path, notice: 'Access denied.' and return
      end
      check_staff_access unless current_user.is_admin?
    end

    def check_staff_access
      allowed = %w(people events)
      unless allowed.include?(params[:controller].split('/').last)
        redirect_to admin_people_path, notice: 'Access denied.' and return
      end
    end


    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    def records_per_page
      params[:per_page] || 55
    end
  end
end
