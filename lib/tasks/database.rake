module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      def structure_dump(filename)
        set_psql_env
        search_path = configuration['schema_search_path']
        unless search_path.blank?
          search_path = search_path.split(",").map{|search_path_part| "--schema=#{Shellwords.escape(search_path_part.strip)}" }.join(" ")
        end

        command = "pg_dump -s -x -O -f #{Shellwords.escape(filename)} #{search_path} #{Shellwords.escape(configuration['database'])}"
        raise 'Error dumping database' unless Kernel.system(command)

        File.open(filename, "a") { |f| f << "SET search_path TO #{ActiveRecord::Base.connection.schema_search_path};\n\n" }
      end
    end
  end
end
