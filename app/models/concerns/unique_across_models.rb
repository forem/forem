# extend to add :unique_across_models, which validates a slug or name across
# all registered models via CrossModelSlug
module UniqueAcrossModels
  def unique_across_models(attribute, **options)
    CrossModelSlug.register(self, attribute)
    validates attribute, presence: true
    validates attribute, cross_model_slug: true, **options, if: :"#{attribute}_changed?"
  end
end
