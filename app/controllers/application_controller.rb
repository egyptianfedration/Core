class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :clear_redirect_club_if_necessary
  before_filter :configure_permitted_parameters, if: :devise_controller?
  after_filter :store_location
  after_filter :set_access_control_headers

  protected

  def clear_redirect_club_if_necessary
    # if the user gets distracted while logging in and does something else and then goes back later to log in, we don't want to redirect them to the source club in that case
    session.delete(:redirect_club_id) unless request.fullpath =~ /\/users/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u|
      u.permit(:club_id, :name, :si_number, :referred_from, :password, :email)
    }
    
    devise_parameter_sanitizer.for(:account_update) { |u|
      u.permit(:club_id, :name, :si_number, :email, :password, :current_password)
    }
  end

  def store_location
    # store last url as long as it isn't a /users path, except if it is a profile page
    if not request.xhr? and (not (request.fullpath =~ /\/users/) or request.fullpath =~ /\/users\/\b\d+\b/) then
      session[:previous_url] = request.fullpath
    end 
    
  end

  def after_sign_in_path_for(resource)
    current_user.sign_in 
    redirect_club_id = session[:redirect_club_id]
    unless redirect_club_id.nil? then
      club = Club.find_by_id(redirect_club_id)
      session[:redirect_club_id] = nil
      current_user.post_sign_in_clubsite_redirect_for_club(club)
    else
      session[:previous_url] || root_path
    end
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def not_found(message)
    redirect_to '/', alert: message
  end
end
