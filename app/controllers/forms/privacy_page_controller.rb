module Forms
  class PrivacyPageController < BaseController
    before_action :require_approved_uh_privacy_notice

    def show
      @privacy_policy_url = current_context.form.privacy_policy_url
    end

  private

    def require_approved_uh_privacy_notice
      return if Settings.uh_forms.privacy_notice_approved == true

      render template: "errors/privacy_notice_unavailable", status: :service_unavailable
    end
  end
end
