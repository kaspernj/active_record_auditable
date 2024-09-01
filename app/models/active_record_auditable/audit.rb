class ActiveRecordAuditable::Audit < ApplicationRecord
  self.table_name = "audits"

  belongs_to :audit_action, class_name: "ActiveRecordAuditable::AuditAction"

  # serialize :audited_changes, coder: JSON

  scope :where_action, ->(action) { joins(:audit_action).where(audit_actions: {action:}) }

  delegate :action, to: :audit_action

  def action=(action_name)
    self.audit_action = ActiveRecordAuditable::AuditAction.find_or_create_by!(action: action_name)
  end
end
