class ActiveRecordAuditable::AuditClasses < ActiveRecordAuditable::ApplicationService
  def perform
    Rails.application.eager_load!
    succeed!(audit_classes:)
  end

  def audit_classes
    @audit_classes ||= begin
      audit_classes = []
      audit_classes << ActiveRecordAuditable::Audit

      ActiveRecordAuditable::BaseAudit.descendants.each do |klass|
        audit_classes << klass
      end

      audit_classes
    end
  end
end
