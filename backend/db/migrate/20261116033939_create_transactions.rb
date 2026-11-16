class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :kind, null: false
      t.string :description, null: false
      t.bigint :amount_cents, null: false
      t.date :occurred_on, null: false

      t.timestamps
    end

    add_index :transactions, %i[user_id occurred_on]
    add_check_constraint :transactions, "amount_cents > 0", name: "transactions_amount_positive"
  end
end
