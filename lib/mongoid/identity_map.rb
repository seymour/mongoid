require 'singleton'

module Mongoid
  class IdentityMap < Hash
    include Singleton
    
    def get(klass, identifier)
      documents_for(klass)[identifier]
    end
    
    def remove(document)
      return nil unless document && document.id
      documents_for(document.class).delete(document.id)
    end
    
    def set(document)
      return nil unless document && document.id
      documents_for(document.class)[document.id] = document
    end
    
    def set_many(document, selector)
      (documents_for(document.class)[selector] ||= []).push(document)
    end
    
    def set_one(document, selector)
      documents_for(document.class)[selector] = document
    end
    
    private
    
    def documents_for(klass)
      self[klass] ||= {}
    end            
  end
end