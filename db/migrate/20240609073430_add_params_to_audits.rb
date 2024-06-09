class AddParamsToAudits < ActiveRecord::Migration[7.1]
  def change
    add_column :audits, :params, :json
  end
end
