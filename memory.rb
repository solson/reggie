class Memory
  include Enumerable

  def initialize(capacity)
    @capacity = capacity
    @memory = []
  end

  def <<(elem)
    @memory << elem
    @memory.shift if @memory.length > @capacity
    self
  end

  def each(*args, &blk)
    @memory.each(*args, &blk)
  end

  def length
    @memory.length
  end

  def [](*args)
    @memory[*args]
  end
end
