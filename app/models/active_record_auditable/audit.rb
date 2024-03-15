class ActiveRecordAuditable::Audit < ApplicationRecord
  self.table_name = "audits"

  belongs_to :audit_action, class_name: "ActiveRecordAuditable::AuditAction"
  belongs_to :audit_auditable_type, class_name: "ActiveRecordAuditable::AuditAuditableType"
  belongs_to :auditable, optional: true, polymorphic: true

  serialize :audited_changes, coder: JSON

  scope :where_action, ->(action) { joins(:audit_action).where(audit_actions: {action:}) }

  delegate :action, to: :audit_action

  before_validation :set_audit_auditable_type

  def action=(action_name)
    self.audit_action = ActiveRecordAuditable::AuditAction.find_or_create_by!(action: action_name)
  end

private

  def set_audit_auditable_type
    self.audit_auditable_type = ActiveRecordAuditable::AuditAuditableType.find_or_create_by!(name: auditable_type) if !audit_auditable_type && auditable_type?
  end
end
