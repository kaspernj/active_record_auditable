class ActiveRecordAuditable::FindOrCreateAction < ActiveRecordAuditable::ApplicationService
  arguments :action

  def perform
    audit_monitor.synchronize do
      succeed! ActiveRecordAuditable::AuditAction.find_or_create_by!(action:)
    end
  end

  def audit_monitor
    @@audit_monitor ||= Monitor.new # rubocop:disable Style/ClassVars
  end
end
