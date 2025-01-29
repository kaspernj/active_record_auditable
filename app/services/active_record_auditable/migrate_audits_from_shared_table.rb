class ActiveRecordAuditable::MigrateAuditsFromSharedTable < ActiveRecordAuditable::ApplicationService
  arguments :model_class

  def perform
    while audits_in_general_table_exists?
      sql = "SELECT * FROM audits WHERE auditable_type = '#{model_class.name}' LIMIT 1000"
      records = model_class.connection.execute(sql).to_a(as: :hash)

      insert_sql = "INSERT INTO `#{new_table_name}` ("
      insert_sql << "`#{model_class.model_name.param_key}_id`"
      delete_sql = "DELETE FROM `audits` WHERE `#{id_column_name}` IN ("
      records_count = 0

      records.first.keys.each do |key|
        next if key == "auditable_id" || key == "auditable_type" || key == "audit_auditable_type_id"

        key = "current_user_id" if key == "user_id"
        insert_sql << ", `#{key}`"
      end


      insert_sql << ") VALUES "
      inserts = []

      records.each_with_index do |data, data_index|
        delete_sql << ", " if data_index > 0
        delete_sql << model_class.connection.quote(data.fetch(id_column_name))

        insert_sql << ", " if data_index > 0
        insert_sql << "("
        insert_sql << model_class.connection.quote(data.fetch("auditable_id"))

        data.each do |key, value|
          next if key == "auditable_id" || key == "auditable_type" || key == "audit_auditable_type_id"

          insert_sql << ", "
          insert_sql << model_class.connection.quote(value)
        end

        insert_sql << ")"
        records_count += 1

        break if insert_sql.bytesize >= 5.megabytes
      end

      delete_sql << ")"

      ActiveRecordAuditable::Audit.transaction do
        create_result = ActiveRecordAuditable::Audit.connection.execute(insert_sql)
        delete_result = ActiveRecordAuditable::Audit.connection.execute(delete_sql)
      end
    end

    succeed!
  end

  def audits_in_general_table_exists?
    sql = "SELECT 1 FROM audits WHERE auditable_type = '#{model_class.name}' LIMIT 1"
    results = model_class.connection.execute(sql).first
    results&.length&.positive?
  end

  def id_column_name
    @id_column_name ||= model_class.primary_key
  end

  def new_table_name
    @new_table_name ||= "#{model_class.table_name.singularize}_audits"
  end
end
