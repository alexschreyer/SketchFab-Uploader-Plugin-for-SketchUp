module Parts
  class StreamParam
    def initialize(stream, size)
      @stream, @size = stream, size
    end
    
    def size
      @size
    end

    def read(offset, how_much)
      @stream.read(how_much)
    end
  end

  class StringParam
    def initialize (str)
      @str = str
    end

    def size
      @str.length
    end

    def read (offset, how_much)
      @str[offset, how_much]
    end
  end
end
