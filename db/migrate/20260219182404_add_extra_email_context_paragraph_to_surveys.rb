class AddExtraEmailContextParagraphToSurveys < ActiveRecord::Migration[7.0]
  def change
    add_column :surveys, :extra_email_context_paragraph, :text
  end
end
