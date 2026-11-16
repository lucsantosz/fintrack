class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: true, foreign_key: true
      t.string :name, null: false
      t.integer :kind, null: false

      t.timestamps
    end

    add_index :categories, %i[user_id kind name], unique: true
  end
end
