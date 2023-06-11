class AddIndexForDocumentTextSearch < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TABLE documents
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('german', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('german', coalesce(body,'')), 'B')
      ) STORED;
    SQL
  end

  def down
    remove_column :documents, :searchable
  end
end
