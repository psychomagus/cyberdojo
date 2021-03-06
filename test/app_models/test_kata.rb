#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/model_test_case'

class KataTests < ModelTestCase

  test 'id read back as set' do
    json_and_rb do
      kata = @dojo.katas[id]
      assert_equal Id.new(id), kata.id
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exists? is false for empty-string id' do
    json_and_rb do
      kata = @dojo.katas[id='']
      assert !kata.exists?
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exists? is false before dir is made' do
    json_and_rb do
      kata = @dojo.katas[id]
      assert !kata.exists?
      @paas.dir(kata).make
      assert kata.exists?
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'make_kata with default-id and default-now' +
       ' creates unique-id and uses-time-now' do
    json_and_rb do
      language = @dojo.languages['Java-JUnit']
      @paas.dir(language).spy_read('manifest.json', JSON.unparse({
        :unit_test_framework => 'JUnit'
      }))
      exercise = @dojo.exercises['test_Yahtzee']
      @paas.dir(exercise).spy_read('instructions', 'your task...')
      now = Time.now
      past = Time.mktime(now.year, now.month, now.day, now.hour, now.min, now.sec)
      kata = @dojo.make_kata(language, exercise)
      assert_not_equal id, kata.id
      created = Time.mktime(*kata.created)
      diff = created - past
      assert 0 <= diff && diff <= 1, "created=#{created}, past=#{past}, diff=#{past}"
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'make_kata saves manifest in kata dir' do
    json_and_rb do |format|
      language = @dojo.languages['Java-JUnit']
      @paas.dir(language).spy_read('manifest.json', JSON.unparse({
        :unit_test_framework => 'waffle'
      }))
      exercise = @dojo.exercises['test_Yahtzee']
      @paas.dir(exercise).spy_read('instructions', 'your task...')
      now = [2014,7,17,21,15,45]
      kata = @dojo.make_kata(language, exercise, id, now)

      expected_manifest = {
        :created => now,
        :id => id,
        :language => language.name,
        :exercise => exercise.name,
        :unit_test_framework => 'waffle',
        :tab_size => 4,
        :visible_files => {
          'output' => '',
          'instructions' => 'your task...'
        }
      }
      if format == 'rb'
        assert @paas.dir(kata).log.include?([ 'write', 'manifest.rb', expected_manifest.inspect ]),
          @paas.dir(kata).log.inspect
      end
      if format == 'json'
        assert @paas.dir(kata).log.include?([ 'write', 'manifest.json', JSON.unparse(expected_manifest) ]),
          @paas.dir(kata).log.inspect
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'kata.id, kata.created, kata.language.name,' +
       ' kata.exercise.name, kata.visible_files' +
       ' all read from manifest' do
    json_and_rb do
      language = @dojo.languages['test-C++-catch']
      visible_files = {
          'wibble.hpp' => '#include <iostream>',
          'wibble.cpp' => '#include "wibble.hpp"'
      }
      @paas.dir(language).spy_read('manifest.json', JSON.unparse({
        :visible_filenames => visible_files.keys
      }))
      @paas.dir(language).spy_read('wibble.hpp', visible_files['wibble.hpp'])
      @paas.dir(language).spy_read('wibble.cpp', visible_files['wibble.cpp'])
      exercise = @dojo.exercises['test_Yahtzee']
      @paas.dir(exercise).spy_read('instructions', 'your task...')
      now = [2014,7,17,21,15,45]
      kata = @dojo.make_kata(language, exercise, id, now)
      assert_equal id, kata.id.to_s
      assert_equal Time.mktime(*now), kata.created
      assert_equal language.name, kata.language.name
      assert_equal exercise.name, kata.exercise.name
      expected_visible_files = {
        'output' => '',
        'instructions' => 'your task...',
        'wibble.hpp' => visible_files['wibble.hpp'],
        'wibble.cpp' => visible_files['wibble.cpp'],
      }
      assert_equal expected_visible_files, kata.visible_files
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'start_avatar with specific avatar' do
    json_and_rb do
      kata = make_kata
      avatar = kata.start_avatar(['hippo'])
      assert_equal 'hippo', avatar.name
      assert_equal ['hippo'], kata.avatars.map {|avatar| avatar.name}
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'start_avatar with avatar-names preference' do
    json_and_rb do
      kata = make_kata
      names = [ 'panda', 'lion', 'cheetah' ]
      panda = kata.start_avatar(names)
      assert_equal 'panda', panda.name
      lion = kata.start_avatar(names)
      assert_equal 'lion', lion.name
      cheetah = kata.start_avatar(names)
      assert_equal 'cheetah', cheetah.name
      assert_equal nil, kata.start_avatar(names)
      avatars_names = kata.avatars.map {|avatar| avatar.name}
      assert_equal names.sort, avatars_names.sort
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'start_avatar succeeds once for each avatar name then fails' do
    json_and_rb do
      kata = make_kata
      created = [ ]
      Avatars.names.length.times do |n|
        avatar = kata.start_avatar
        assert_not_nil avatar
        created << avatar
      end
      assert_equal Avatars.names.sort, created.collect{|avatar| avatar.name}.sort
      avatar = kata.start_avatar
      assert_nil avatar
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'old kata with rb manifest file reports its format as rb' do
    json_and_rb do
      id = '12345ABCDE'
      kata = Kata.new(@dojo, id)
      @paas.dir(kata).make
      @paas.dir(kata).spy_exists?('manifest.rb')
      assert_equal 'rb', kata.format
      assert kata.format === 'rb'
      assert_equal 'manifest.rb', kata.manifest_filename
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'kata without manifest yet' +
       " reports its manifest_filename in dojo's format" do
    json_and_rb do |format|
      id = '12345ABCDE'
      kata = Kata.new(@dojo, id)
      assert_equal format, kata.format
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test kata has been entered? if it has at least one avatar
  # test kata is not active? when it does not exist
  # test kata is not active? when all its avatars have less than 2 traffic-lights
  # test kata is active? when at least one avatar has 2 or more traffic-lights

  # test kata age is zero when not active
  # test kata age is from earliest 2nd traffic-light to now when active
  # test kata age is from earliest 2nd traffic-light to max of one day
  # test kata expired? is false when age is less than one day
  # test kata expired? is true when age is greater than or equal to one day

  def make_kata
    language = @dojo.languages['test-C++-Catch']
    visible_files = {
        'wibble.hpp' => '#include <iostream>',
        'wibble.cpp' => '#include "wibble.hpp"'
    }
    @paas.dir(language).spy_read('manifest.json', JSON.unparse({
      :visible_filenames => visible_files.keys
    }))
    @paas.dir(language).spy_read('wibble.hpp', visible_files['wibble.hpp'])
    @paas.dir(language).spy_read('wibble.cpp', visible_files['wibble.cpp'])
    exercise = @dojo.exercises['test_Yahtzee']
    @paas.dir(exercise).spy_read('instructions', 'your task...')
    @dojo.make_kata(language, exercise)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def id
    '45ED23A2F1'
  end

end
