module ExecJS
  class DisabledRuntime
    def name
      "Disabled"
    end

    def exec(source)
      raise Error, "ExecJS disabled"
    end

    def eval(source)
      raise Error, "ExecJS disabled"
    end

    def compile(source)
      raise Error, "ExecJS disabled"
    end

    def available?
      true
    end
  end
end
