
class SpyDir
  include Enumerable

  def initialize(disk, dir)
    @disk,@dir = disk,dir
    @log = [ ]
    @spy_log = [ ]
  end

  attr_reader :log

  def teardown
    @spy_log.each do |entry|
      assert log.include?(entry), "log.include?(#{entry})"
    end
  end

  def path
    @dir
  end

  def each
    @disk.dirs_each(self) do |subdir|
      yield subdir
    end
  end

  def make
    @repo ||= { }
  end

  # - - - - - - - - - - - - - - -

  def spy_exists?(filename)
    @spy_log << ['exists',filename]
  end

  def exists?(filename = '')
    return false if @repo === nil    # no dir().make yet
    return true  if filename === ''  # the repo exists for the dir
    @log << ['exists',filename]
    @repo[filename] != nil || @spy_log.include?(['exists',filename])
  end

  # - - - - - - - - - - - - - - -

  def spy_write(filename, content)
    @spy_log << ['write',filename,content]
  end

  def write(filename, content)
    if filename.end_with?('.rb')
      assert content.class != String, "write('#{filename}',content.class != String)"
      content = content.inspect
    end
    if filename.end_with?(".json")
      assert content.class != String, "write('#{filename}',content.class != String)"
      content = JSON.unparse(content)
    end
    @log << ['write',filename,content]
    make
    @repo[filename] = content
  end

  # - - - - - - - - - - - - - - -

  def spy_read(filename, content)
    make
    @repo[filename] = content
    @spy_log << ['read',filename,content]
  end

  def read(filename)
    assert @repo != nil, "read('#{filename}') no stub file"
    assert @repo[filename] != nil, "read('#{filename}') no stub file"
    content  = @repo[filename]
    @log << ['read',filename,content]
    content
  end

  # - - - - - - - - - - - - - - -

  def lock(&block)
    block.call
  end

private

  def assert(truth, message)
    raise "SpyDir['#{@dir}'].#{message}" if !truth
  end

end
