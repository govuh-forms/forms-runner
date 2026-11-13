class CreateFormMetricEvents < ActiveRecord::Migration[8.1]
  def up
    create_table :form_metric_events do |t|
      t.integer :form_id, null: false
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.bigint :submission_id
    end
    add_check_constraint :form_metric_events,
                         "event_type IN ('started', 'submitted')",
                         name: "form_metric_events_event_type_check"
    add_index :form_metric_events, [:form_id, :occurred_at, :event_type],
              name: "form_metric_events_form_date_type"
    add_index :form_metric_events, :submission_id, unique: true
    create_table :form_metrics_configuration do |t|
      t.datetime :collection_started_at, null: false
    end
    execute "INSERT INTO form_metrics_configuration (collection_started_at) VALUES (clock_timestamp())"
    execute <<~SQL
      INSERT INTO form_metric_events (form_id, event_type, occurred_at, submission_id)
      SELECT form_id, 'submitted', created_at, id
      FROM submissions
      WHERE mode = 'form'
      ON CONFLICT (submission_id) DO NOTHING
    SQL
    execute <<~SQL
      CREATE OR REPLACE VIEW form_submission_daily_summary AS
      SELECT form_id,
             ((occurred_at AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/London')::date AS activity_date,
             count(*) FILTER (WHERE event_type = 'submitted')::bigint AS completed_count,
             count(*) FILTER (WHERE event_type = 'started')::bigint AS started_count
      FROM form_metric_events
      GROUP BY form_id, ((occurred_at AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/London')::date
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS form_submission_daily_summary;
      CREATE VIEW form_submission_daily_summary AS
      SELECT form_id,
             ((created_at AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/London')::date AS activity_date,
             count(*)::bigint AS completed_count
      FROM submissions
      WHERE mode = 'form'
      GROUP BY form_id, ((created_at AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/London')::date
    SQL
    drop_table :form_metric_events
    drop_table :form_metrics_configuration
  end
end
