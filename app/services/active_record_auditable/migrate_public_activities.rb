class ActiveRecordAuditable::MigratePublicActivities < ActiveRecordAuditable::ApplicationService
  def perform
    loop do
      records = ApplicationRecord.connection.execute("SELECT * FROM activities ORDER BY trackable_type, created_at LIMIT 1000").to_a(as: :hash)

      break if records.empty?

      inserts = {}
      ids = []

      records.each do |record|
        key_match = record.fetch("key").match(/(.+)\.(.+)$/)

        action_name = key_match[1]
        action = ActiveRecordAuditable::FindOrCreateAction.execute!(action: action_name)

        parameters = record.fetch("parameters")
        params = parameters.delete_prefix("--- ").delete_suffix("\n") if parameters

        insert = {
          audit_action_id: action.id,
          created_at: record.fetch("created_at"),
          id: record.fetch("id"),
          params:,
          updated_at: record.fetch("updated_at")
        }

        trackable_type = record.fetch("trackable_type")
        dedicated_table_name = "#{trackable_type.underscore}_audits"
        dedicated_table_exists = ActiveRecordAuditable::Audited.__cached_audit_table_names.key?(dedicated_table_name)

        if dedicated_table_exists
          foreign_key = "#{trackable_type.underscore}_id"

          insert[foreign_key] = record.fetch("trackable_id")
        else
          auditable_type = ActiveRecordAuditable::AuditAuditableType.find_or_create_by!(name: trackable_type)

          insert[:audit_auditable_type_id] = auditable_type.id
          insert[:auditable_type] = trackable_type
          insert[:auditable_id] = record.fetch("trackable_id")
        end

        inserts[trackable_type] ||= []
        inserts[trackable_type] << insert

        raise "ID already exists: #{record.fetch("id")}" if ids.include?(record.fetch("id"))

        ids << record.fetch("id")
      end

      inserts.each do |trackable_type, inserts_for_trackable_type|
        dedicated_table_name = "#{trackable_type.underscore}_audits"
        dedicated_table_exists = ActiveRecordAuditable::Audited.__cached_audit_table_names.key?(dedicated_table_name)

        sql = "INSERT INTO "

        if dedicated_table_exists
          sql << dedicated_table_name
        else
          sql << "audits"
        end

        sql << " ("

        first = true
        inserts_for_trackable_type[0].each_key do |key|
          if first
            first = false
          else
            sql << ", "
          end

          sql << "`#{key}`"
        end

        sql << ") VALUES "

        first = true
        inserts_for_trackable_type.each do |insert|
          if first
            first = false
          else
            sql << ", "
          end

          sql << "\n(\n"
          first_value = true

          insert.each do |key, value|
            if first_value
              first_value = false
            else
              sql << ",\n"
            end

            sql << "  #{ApplicationRecord.connection.quote(value)}"
          end

          sql << "\n)"
        end

        ApplicationRecord.connection.execute(sql)
      end

      ids_quoted = ids.map { |id| ApplicationRecord.connection.quote(id) }

      ApplicationRecord.connection.execute("DELETE FROM activities WHERE id IN (#{ids_quoted.join(", ")})")
    end

    succeed!
  end
end

=begin
{"id"=>"96614bc5-1735-11ee-869e-024217000003",
  "trackable_type"=>"StripeCharge",
  "trackable_id"=>"ffd1c84b-b6c1-4762-a8b6-0659ddff9a83",
  "owner_type"=>nil,
  "owner_id"=>nil,
  "key"=>"stripe_charge.create",
  "parameters"=>nil,
  "recipient_type"=>nil,
  "recipient_id"=>nil,
  "created_at"=>2023-06-30 11:02:21 UTC,
  "updated_at"=>2023-06-30 11:02:21 UTC}
=end
