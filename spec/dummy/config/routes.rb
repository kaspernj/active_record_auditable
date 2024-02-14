Rails.application.routes.draw do
  mount ActiveRecordAuditable::Engine => "/active_record_auditable"
end
