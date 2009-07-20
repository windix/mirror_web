module TagsHelper
  #TODO: copied from plugins' directory
  def tag_cloud(tags, classes)
    return if tags.empty?
    
    max_count = tags.sort_by(&:count).last.count.to_f
    
    tags.each do |tag|
      index = ((tag.count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def related_tag_path(current_tags, related_tag)
    tags = current_tags.dup
    
    tags << related_tag
    tag_path(tags.join(','))
  end
end
