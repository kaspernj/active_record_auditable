require "active_record_auditable/version"
require "active_record_auditable/engine"
require "service_pattern"

module ActiveRecordAuditable
  autoload :Audited, "#{__dir__}/active_record_auditable/audited"
end
