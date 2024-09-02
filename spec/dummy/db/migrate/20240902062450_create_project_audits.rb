# frozen_string_literal: true

class CreateProjectAudits < ActiveRecord::Migration[7.2]
  def up
    ActiveRecordAuditable::CreateAuditsTableForModelClass.execute!(model_class: Project)
  end

  def down
    drop_table :project_audits
  end
end
