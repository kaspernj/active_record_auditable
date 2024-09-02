class ActiveRecordAuditable::BaseAudit < ActiveRecordAuditable::ApplicationRecord
  self.abstract_class = true

  def self.inherited(child)
    super

    child.include ActiveRecordAuditable::ActsAsJson

    child.acts_as_json :audited_changes
    child.acts_as_json :extra_liquid_variables
    child.acts_as_json :params
  end

  belongs_to :audit_action, class_name: "ActiveRecordAuditable::AuditAction"

  scope :where_action, ->(action) { joins(:audit_action).where(audit_actions: {action:}) }

  delegate :action, to: :audit_action

  def action=(action_name)
    self.audit_action = ActiveRecordAuditable::AuditAction.find_or_create_by!(action: action_name)
  end
end
