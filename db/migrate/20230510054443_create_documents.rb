class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.text :body
      t.text :title

      t.timestamps
    end
  end
end
