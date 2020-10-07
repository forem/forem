json.array! @follows.each do |follow|
  json.extract!(follow.followable, :id, :name)
  json.extract!(follow, :points)
end
