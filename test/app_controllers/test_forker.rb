#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../app_models/spy_disk'
require File.dirname(__FILE__) + '/../app_models/spy_git'
require File.dirname(__FILE__) + '/../app_models/spy_runner'
require './integration_test'

class ForkerControllerTest < IntegrationTest

  def thread
    Thread.current
  end

  def teardown
    thread[:disk] = nil
    thread[:git] = nil
    thread[:runner] = nil
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "if id is bad " +
       "then fork fails " +
       "and the reason is id" do
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new

    get "forker/fork",
      :format => :json,
      :id => 'bad',
      :avatar => 'hippo',
      :tag => 1

    assert_not_nil json, "assert_not_nil json"
    assert_equal false, json['forked'], json.inspect
    assert_equal 'id', json['reason'], json.inspect
    assert_nil json['id'], "json['id']==nil"
    assert_equal({ }, git.log)
    disk.teardown
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "if language folder no longer exists " +
        "the fork fails " +
        "and the reason is language" do
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new
    thread[:runner] = runner = SpyRunner.new
    paas = Paas.new(disk, git, runner)
    dojo = Dojo.new(paas, root_path, 'json')
    language = dojo.languages['xxxx']
    id = '1234512345'
    kata = dojo.katas[id]
    paas.dir(kata).spy_read('manifest.rb', { :language => language.name }.inspect)

    get "forker/fork",
      :format => :json,
      :id => id,
      :avatar => 'hippo',
      :tag => 1

    assert_not_nil json, "assert_not_nil json"
    assert_equal false, json['forked'], json.inspect
    assert_equal 'language', json['reason'], json.inspect
    assert_equal language.name, json['language'], json.inspect
    assert_nil json['id'], "json['id']==nil"
    assert_equal({ }, git.log)
    disk.teardown
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "if avatar not started " +
       "the fork fails " +
       "and the reason is avatar" do
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new
    thread[:runner] = runner = SpyRunner.new
    paas = Paas.new(disk, git, runner)
    dojo = Dojo.new(paas, root_path, 'json')
    language = dojo.languages['Ruby-installed-and-working']
    paas.dir(language).make
    paas.dir(language).spy_exists?('manifest.json')

    id = '1234512345'
    kata = dojo.katas[id]
    paas.dir(kata).spy_read('manifest.json', JSON.unparse({ :language => language.name }))

    get "forker/fork",
      :format => :json,
      :id => id,
      :avatar => 'hippo',
      :tag => 1

    assert_not_nil json, "assert_not_nil json"
    assert_equal false, json['forked'], json.inspect
    assert_equal 'avatar', json['reason'], json.inspect
    assert_nil json['id'], "json['id']==nil"
    assert_equal({ }, git.log)
    disk.teardown
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "if tag is bad " +
       "the fork fails " +
       "and the reason is tag" do
    bad_tag_test('xx')
    bad_tag_test('-14')
    bad_tag_test('-1')
    bad_tag_test('0')
    bad_tag_test('2')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def bad_tag_test(bad_tag)
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new
    thread[:runner] = runner = SpyRunner.new
    paas = Paas.new(disk, git, runner)
    dojo = Dojo.new(paas, root_path, 'json')
    language_name = 'Ruby-installed-and-working'
    language = dojo.languages[language_name]
    paas.dir(language).make
    paas.dir(language).spy_exists?('manifest.json')

    id = '1234512345'
    kata = dojo.katas[id]
    paas.dir(kata).spy_read('manifest.rb', { :language => language_name }.inspect)
    avatar_name = 'hippo'
    avatar = kata.avatars[avatar_name]
    paas.dir(avatar).spy_read('increments.rb', [{
        "colour" => "red",
        "time" => [2014, 2, 15, 8, 54, 6],
        "number" => 1
      }].inspect)

    get "forker/fork",
      :format => :json,
      :id => id,
      :avatar => avatar_name,
      :tag => bad_tag

    assert_not_nil json, "assert_not_nil json"
    assert_equal false, json['forked'], json.inspect
    assert_equal 'tag', json['reason'], json.inspect
    assert_nil json['id'], "json['id']==nil"
    assert_equal({ }, git.log)
    disk.teardown
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "when language has been renamed but new-name-language exists " +
       "and id,avatar,tag all ok " +
       "the fork works " +
       "and new dojo's id is returned" do
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new
    thread[:runner] = runner = SpyRunner.new
    paas = Paas.new(disk, git, runner)
    dojo = Dojo.new(paas, root_path, 'json')
    id = '1234512345'
    kata = dojo.katas[id]

    old_language_name = 'C#'
    new_language_name = 'C#-NUnit'
    paas.dir(kata).spy_read('manifest.rb', { :language => old_language_name }.inspect)
    language = dojo.languages[new_language_name]
    paas.dir(language).spy_read('manifest.json', JSON.unparse(
      {
        'unit_test_framework' => 'fake'
      }))

    avatar_name = 'hippo'
    avatar = kata.avatars[avatar_name]
    paas.dir(avatar).spy_read('increments.rb', [
      {
        "colour" => "red",
        "time" => [2014, 2, 15, 8, 54, 6],
        "number" => 1
      },
      {
        "colour" => "green",
        "time" => [2014, 2, 15, 8, 54, 34],
        "number" => 2
      },
      ].inspect)

    get "forker/fork",
      :format => :json,
      :id => id,
      :avatar => avatar_name,
      :tag => 2

    assert_not_nil json, "assert_not_nil json"
    assert_equal true, json['forked'], json.inspect
    assert_not_nil json['id'], json.inspect
    assert_equal 10, json['id'].length
    assert_not_equal id, json['id']
    assert dojo.katas[json['id']].exists?
    # need to be able to properly stub in SpyGit so I can return manifest
    # and assert new dojo has same settings as one forked from
    assert_equal({paas.path(avatar) => [ ["show", "2:manifest.rb"]]}, git.log)
    disk.teardown
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "when id,language,avatar,tag all ok " +
       "the fork works " +
       "and new dojo's id is returned" do
    thread[:disk] = disk = SpyDisk.new
    thread[:git] = git = SpyGit.new
    thread[:runner] = runner = SpyRunner.new
    paas = Paas.new(disk, git, runner)
    dojo = Dojo.new(paas, root_path, 'json')
    language_name = 'Ruby-installed-and-working'
    id = '1234512345'
    kata = dojo.katas[id]
    paas.dir(kata).spy_read('manifest.rb', { :language => language_name }.inspect)
    language = dojo.languages[language_name]
    paas.dir(language).spy_read('manifest.json', JSON.unparse(
      {
        'unit_test_framework' => 'fake'
      }))
    avatar_name = 'hippo'
    avatar = kata.avatars[avatar_name]
    paas.dir(avatar).spy_read('increments.rb', [
      {
        "colour" => "red",
        "time" => [2014, 2, 15, 8, 54, 6],
        "number" => 1
      },
      {
        "colour" => "green",
        "time" => [2014, 2, 15, 8, 54, 34],
        "number" => 2
      },
      ].inspect)

    get "forker/fork",
      :format => :json,
      :id => id,
      :avatar => avatar_name,
      :tag => 2

    assert_not_nil json, "assert_not_nil json"
    assert_equal true, json['forked'], json.inspect
    assert_not_nil json['id'], json.inspect
    assert_equal 10, json['id'].length
    assert_not_equal id, json['id']
    assert dojo.katas[json['id']].exists?
    # need to be able to properly stub in SpyGit so I can return manifest
    # and assert new dojo has same settings as one forked from
    assert_equal({paas.path(avatar) => [ ["show", "2:manifest.rb"]]}, git.log)
    disk.teardown
  end

end
