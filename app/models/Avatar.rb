require 'forwardable'

class Avatar
  extend Forwardable

  def initialize(kata, name)
    @kata,@name = kata,name
  end

  attr_reader :kata, :name

  def_delegators :kata, :format

  def exists?
    Avatars.names.include?(name) && paas.exists?(self)
  end

  def active?
    # o) Players commonly start two avatars on the same computer and use
    #    one solely to read the instructions. I don't want these avatars
    #    appearing on the dashboard.
    # o) When an avatar enters a cyber-dojo the tests are automatically
    #    run. This means an avatar gets one traffic-light for free.
    # o) When forking a new kata it is common to enter as one animal
    #    to sanity check it is ok (but not press [test])
    lights.count > 1
  end

  def sandbox
    Sandbox.new(self)
  end

  def save(delta, visible_files)
    delta[:changed].each do |filename|
      paas.write(sandbox, filename, visible_files[filename])
    end
    delta[:new].each do |filename|
      paas.write(sandbox, filename, visible_files[filename])
      paas.git_add(sandbox, filename)
    end
    delta[:deleted].each do |filename|
      paas.git_rm(sandbox, filename)
    end
  end

  def test(max_duration)
    output = paas.run(sandbox, './cyber-dojo.sh', max_duration)
    output.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace)
  end

  def save_visible_files(visible_files)
    paas.write(self, visible_files_filename, visible_files)
  end

  def save_traffic_light(traffic_light, now)
    lights = traffic_lights
    lights << traffic_light
    traffic_light['number'] = lights.length
    traffic_light['time'] = now
    paas.write(self, traffic_lights_filename, lights)
    lights
  end

  def commit(tag)
    paas.git_commit(self, "-a -m '#{tag}' --quiet")
    paas.git_tag(self, "-m '#{tag}' #{tag} HEAD")
  end

  #- - - - - - - - - - - - - - -

  def lights
    Lights.new(self)
  end

  #- - - - - - - - - - - - - - -

  def visible_files(tag = nil)
    parse(visible_files_filename, tag)
  end

  def traffic_lights(tag = nil)
    parse(traffic_lights_filename, tag)
  end

  def diff_lines(was_tag, now_tag)
    command = "--ignore-space-at-eol --find-copies-harder #{was_tag} #{now_tag} sandbox"
    output = paas.git_diff(self, command)
    output.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace)
  end

  def traffic_lights_filename
    'increments.' + format
  end

  def visible_files_filename
    'manifest.' + format
  end

private

  def paas
    kata.dojo.paas
  end

  def parse(filename, tag)
    text = paas.read(self, filename) if tag == nil
    text = paas.git_show(self, "#{tag}:#{filename}") if tag != nil
    return JSON.parse(JSON.unparse(eval(text))) if format === 'rb'
    return JSON.parse(text) if format === 'json'
  end

end
