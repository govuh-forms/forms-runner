module Forms
  class PrivacyPageController < BaseController
    # Only the published, form-specific notice for the existing ministerial EOI
    # may be used while the generic GOV.UH Forms privacy page is not approved.
    MINISTERIAL_EOI_FORM_ID = 1
    MINISTERIAL_EOI_PRIVACY_NOTICE = "https://www.gov.uhrblx.com/guidance/ministerial-expression-of-interest-privacy-notice".freeze

    before_action :require_approved_uh_privacy_notice

    def show
      @privacy_policy_url = current_context.form.privacy_policy_url
    end

  private

    def require_approved_uh_privacy_notice
      return if Settings.uh_forms.privacy_notice_approved == true

      if ministerial_eoi_has_published_notice?
        return redirect_to(MINISTERIAL_EOI_PRIVACY_NOTICE, allow_other_host: true, status: :see_other)
      end

      render template: "errors/privacy_notice_unavailable", status: :service_unavailable
    end

    def ministerial_eoi_has_published_notice?
      current_context.form.id.to_i == MINISTERIAL_EOI_FORM_ID &&
        current_context.form.privacy_policy_url == MINISTERIAL_EOI_PRIVACY_NOTICE
    end
  end
end
