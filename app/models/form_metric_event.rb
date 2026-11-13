# A Forms runner usage event. No answers, addresses, session identifiers or
# submission references are collected. Submission IDs prevent duplicate counts.
class FormMetricEvent < ApplicationRecord
  self.table_name = "form_metric_events"

  def self.record_start(form_id:)
    create!(form_id: Integer(form_id), event_type: "started", occurred_at: Time.current)
  end

  def self.record_submission(submission:)
    create_or_find_by!(submission_id: submission.id) do |event|
      event.form_id = submission.form_id
      event.event_type = "submitted"
      event.occurred_at = submission.created_at
    end
  end
end
