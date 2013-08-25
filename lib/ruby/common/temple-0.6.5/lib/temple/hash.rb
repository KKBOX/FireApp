module Temple
  # Immutable hash class which supports hash merging
  # @api public
  class ImmutableHash
    include Enumerable

    def initialize(*hash)
      @hash = hash.compact
    end

    def include?(key)
      @hash.any? {|h| h.include?(key) }
    end

    def [](key)
      @hash.each {|h| return h[key] if h.include?(key) }
      nil
    end

    def each
      keys.each {|k| yield(k, self[k]) }
    end

    def keys
      @hash.inject([]) {|keys, h| keys += h.keys }.uniq
    end

    def values
      keys.map {|k| self[k] }
    end

    def to_hash
      result = {}
      each {|k, v| result[k] = v }
      result
    end
  end

  # Mutable hash class which supports hash merging
  # @api public
  class MutableHash < ImmutableHash
    def initialize(*hash)
      super({}, *hash)
    end

    def []=(key, value)
      @hash.first[key] = value
    end

    def update(hash)
      @hash.first.update(hash)
    end
  end

  class OptionHash < MutableHash
    def initialize(*hash, &block)
      super(*hash)
      @handler = block
      @valid = {}
      @deprecated = {}
    end

    def []=(key, value)
      validate_key!(key)
      super
    end

    def update(hash)
      validate_hash!(hash)
      super
    end

    def valid_keys
      keys.concat(@valid.keys).uniq
    end

    def add_valid_keys(*keys)
      keys.flatten.each { |key| @valid[key] = true }
    end

    def add_deprecated_keys(*keys)
      keys.flatten.each { |key| @valid[key] = @deprecated[key] = true }
    end

    def validate_hash!(hash)
      hash.to_hash.keys.each {|key| validate_key!(key) }
    end

    def validate_key!(key)
      @handler.call(self, key, true) if deprecated_key?(key)
      @handler.call(self, key, false) unless valid_key?(key)
    end

    def deprecated_key?(key)
      @deprecated.include?(key) ||
        @hash.any? {|h| h.deprecated_key?(key) if h.respond_to?(:deprecated_key?) }
    end

    def valid_key?(key)
      include?(key) || @valid.include?(key) ||
        @hash.any? {|h| h.valid_key?(key) if h.respond_to?(:valid_key?) }
    end
  end
end
