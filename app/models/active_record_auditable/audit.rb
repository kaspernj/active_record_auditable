class ActiveRecordAuditable::Audit < ApplicationRecord
  self.table_name = "audits"

  belongs_to :audit_action, class_name: "ActiveRecordAuditable::AuditAction"
  belongs_to :audit_auditable_type, class_name: "ActiveRecordAuditable::AuditAuditableType"
  belongs_to :auditable, optional: true, polymorphic: true

  serialize :audited_changes, JSON
  serialize :extra_liquid_variables, JSON

  scope :where_action, ->(action) { joins(:audit_action).where(audit_actions: {action:}) }

  delegate :action, to: :audit_action
end
