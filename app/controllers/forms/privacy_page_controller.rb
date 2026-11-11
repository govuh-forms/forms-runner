module Forms
  class PrivacyPageController < BaseController
    # Only these existing, published notices are authorised for the identified
    # Cabinet Office / Chief Minister's Office native forms. No blanket bypass.
    APPROVED_EXISTING_FORM_PRIVACY_NOTICES = {
      1 => "https://www.gov.uhrblx.com/guidance/ministerial-expression-of-interest-privacy-notice",
      17 => "https://www.gov.uhrblx.com/help/privacy-notice",
      18 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
      20 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
      19 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
    }.freeze

    before_action :require_approved_uh_privacy_notice

    def show
      @privacy_policy_url = current_context.form.privacy_policy_url
    end

  private

    def require_approved_uh_privacy_notice
      return if Settings.uh_forms.privacy_notice_approved == true

      approved_url = APPROVED_EXISTING_FORM_PRIVACY_NOTICES[current_context.form.id.to_i]
      if approved_url && current_context.form.privacy_policy_url == approved_url
        return redirect_to(approved_url, allow_other_host: true, status: :see_other)
      end

      render template: "errors/privacy_notice_unavailable", status: :service_unavailable
    end
  end
end
