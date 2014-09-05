# Extends ActiveRecord::SchemaDumper class to dump schemas other than "public"
# and tables from those schemas.
module PgPower::SchemaDumper::SchemaMethods
  # Dump create schema statements
  def header_with_schemas(stream)
    header_without_schemas(stream)
    schemas(stream)
    stream
  end

  # * Dumps schemas.
  # * Dumps tables from public schema using native #tables method.
  # * Dumps tables from schemas other than public.
  def tables_with_schemas(stream)
    public_schema_tables(stream)
    non_public_schema_tables(stream)
  end

  # Generates code to create schemas.
  def schemas(stream)
    # Don't create "public" schema since it exists by default.
    schema_names = PgPower::Tools.schemas - ["public", "information_schema"]
    schema_names.each do |schema_name|
      schema(schema_name, stream)
    end
    stream << "\n"
  end
  private :schemas

  # Generates code to create schema.
  def schema(schema_name, stream)
    stream << "  create_schema \"#{schema_name}\"\n"
  end
  private :schema

  # Dumps tables from public schema
  def public_schema_tables(stream)
    ignored_tables = ['schema_migrations', ignore_tables].flatten.map do |table|
      table.starts_with?('public.') ? table : "public.#{table}"
    end
    get_public_schema_table_names.each do |name|
      begin
        table(name, stream) unless remove_prefix_and_suffix(name).in?(ignored_tables)
      rescue ::ActiveRecord::InsufficientPrivilege => exc
        with_warnings(false) { warn("#{exc.class.name}: #{exc.message}. Skipping #{name.inspect}...") }
      end
    end
  end
  private :public_schema_tables

  # Dumps tables from schemas other than public
  def non_public_schema_tables(stream)
    get_non_public_schema_table_names.each do |name|
      begin
        table(name, stream)
      rescue ::ActiveRecord::InsufficientPrivilege => exc
        with_warnings(false) { warn("#{exc.class.name}: #{exc.message}. Skipping #{name.inspect}...") }
      end
    end
  end
  private :non_public_schema_tables

  # Returns a sorted list of public schema tables
  # Usage:
  #   get_public_schema_table_names # => ['public.cities','public.countries','public.members']

  def get_public_schema_table_names
    result = @connection.query(<<-SQL, 'SCHEMA')
      SELECT schemaname || '.' || tablename
      FROM pg_tables
      WHERE schemaname IN ('public')
      ORDER BY schemaname, tablename
    SQL
    result.flatten
  end
  private :get_public_schema_table_names

  def get_non_public_schema_table_names
    result = @connection.query(<<-SQL, 'SCHEMA')
      SELECT schemaname || '.' || tablename
      FROM pg_tables
      WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'public')
      ORDER BY schemaname, tablename
    SQL
    result.flatten
  end
  private :get_non_public_schema_table_names
end
