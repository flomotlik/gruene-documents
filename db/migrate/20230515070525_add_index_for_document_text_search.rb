class AddIndexForDocumentTextSearch < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TABLE documents
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
        to_tsvector('german', coalesce(body,''))
      ) STORED;
    SQL

    execute <<-SQL
      ALTER TABLE documents
      ADD COLUMN searchable_simple tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(body,''))
      ) STORED;
    SQL
  end

  def down
    remove_column :documents, :searchable
    remove_column :documents, :searchable_simple
  end
end
