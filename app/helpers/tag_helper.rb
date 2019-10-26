module TagHelper
  def partial_file
    "#{name.delete_suffix!('tag').pluralize}/liquid".freeze
  end
end
