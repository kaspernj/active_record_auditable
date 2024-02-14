class ActiveRecordAuditable::Audit < ApplicationRecord
  belongs_to :audit_action, class_name: "ActiveRecordAuditable::AuditAction"
  belongs_to :audit_auditable_type, class_name: "ActiveRecordAuditable::AuditableType"
  belongs_to :auditable, optional: true, polymorphic: true

  serialize :audited_changes, JSON
  serialize :extra_liquid_variables, JSON

  after_save -> { NotificationTypeAuditTriggers::CallTriggers.perform_later.execute!(audit: self) if user.present? }

  scope :where_action, ->(action) { joins(:audit_action).where(audit_actions: {action:}) }
end
