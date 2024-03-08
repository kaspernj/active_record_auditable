class CreateAuditActions < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_actions do |t|
      t.string :action, index: {unique: true}, null: false
      t.timestamps
    end
  end
end
