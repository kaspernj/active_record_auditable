require "active_record_auditable/version"
require "active_record_auditable/engine"

module ActiveRecordAuditable
  autoload :Audited, "#{__dir__}/active_record_auditable/audited"
end
