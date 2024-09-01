class ActiveRecordAuditable::MigrateAuditsFromSharedTable < ActiveRecordAuditable::ApplicationService
  arguments :model_class

  def perform
    while audits_in_general_table_exists?
      sql = "SELECT * FROM audits WHERE auditable_type = '#{model_class.name}' LIMIT 1000"
      records = model_class.connection.execute(sql).to_a(as: :hash)

      insert_sql = "INSERT INTO `#{new_table_name}` ("
      delete_sql = "DELETE FROM `audits` WHERE `#{id_column_name}` IN ("
      records_count = 0

      records.first.keys.each_with_index do |key, index|
        insert_sql << ", " if index > 0
        insert_sql << "`#{key}`"
      end

      insert_sql << ") VALUES "
      inserts = []

      records.each_with_index do |data, data_index|
        if !data["audit_auditable_type_id"]
          auditable_type = ActiveRecordAuditable::AuditAuditableType.find_by!(name: data.fetch("auditable_type"))
          data["audit_auditable_type_id"] = auditable_type.id
        end

        delete_sql << ", " if data_index > 0
        delete_sql << model_class.connection.quote(data.fetch(id_column_name))

        insert_sql << ", " if data_index > 0
        insert_sql << "("

        data.values.each_with_index do |value, value_index|
          insert_sql << ", " if value_index > 0
          insert_sql << model_class.connection.quote(value)

          total_bytesize += (value.to_s.bytesize || 0) + 5
        end

        insert_sql << ")"
        records_count += 1

        break if insert_sql.bytesize >= 5.megabytes
      end

      delete_sql << ")"

      puts "Inserting #{records_count} records of #{total_bytesize / 1.megabyte} megabytes"

      ActiveRecordAuditable::Audit.transaction do
        create_result = ActiveRecordAuditable::Audit.connection.execute(insert_sql)
        delete_result = ActiveRecordAuditable::Audit.connection.execute(delete_sql)

        puts "#{records_count} records migrated"
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
