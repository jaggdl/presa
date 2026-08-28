module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
      Current.team ||= Current.user&.teams&.first
      Current.session
    end

    def find_session_by_cookie
      session_record = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      return nil if session_record.nil?

      if session_record.expired?
        session_record.destroy
        cookies.delete(:session_id)
        return nil
      end

      return rotate_session!(session_record) if session_record.rotation_due?

      session_record.slide_expiry!
      session_record
    end

    # Re-issues a session under a fresh id on a fixed cadence, so a captured
    # cookie stops working shortly after it's stolen (and its expiry resets).
    def rotate_session!(session_record)
      new_session = session_record.user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )
      session_record.destroy
      set_session_cookie(new_session)
      new_session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to Team.first_run? ? new_signup_path : new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        Current.team = user.teams.first
        set_session_cookie(session)
      end
    end

    def set_session_cookie(session_record)
      cookies.signed.permanent[:session_id] = { value: session_record.id, httponly: true, same_site: :lax, secure: request.ssl? }
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
