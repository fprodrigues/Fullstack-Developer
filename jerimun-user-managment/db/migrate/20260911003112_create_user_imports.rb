class CreateUserImports < ActiveRecord::Migration[8.1]
  def change
    create_table :user_imports do |t|
      t.string :status
      t.integer :total_rows
      t.integer :processed_rows
      t.integer :successful_rows
      t.integer :failed_rows
      t.text :error_message
      t.references :created_by, null: false, foreign_key: true

      t.timestamps
    end
  end
end
