class ComplexForms
  include ActiveModel::Model

  def to_key
  end

  def to_model
    self
  end

  def persisted?
    false
  end

  def read_attribute_for_validation(key)
    @attributes[key]
    send(key)
  end

  def self.human_attribute_name(attr, options = {})
    attr
  end

  def self.lookup_ancestors
    [self]
  end
end
