#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../cyberdojo_test_base'
require 'OutputParser'

class OutputCppUTestTests < CyberDojoTestBase

  test 'one failing test is red' do
    output =
      [
       "Errors (1 failures, 1 tests, 1 ran, 5 checks, 0 ignored, 0 filtered out, 1 ms)"
      ].join("\n")
    assert_equal :red, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'one passing test is green' do
    output =
      [
      "OK (1 tests, 1 ran, 5 checks, 0 ignored, 0 filtered out, 0 ms)"
      ].join("\n")
    assert_equal :green, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'two failing tests is red' do
    output =
      [
      "Errors (2 failures, 2 tests, 2 ran, 10 checks, 0 ignored, 0 filtered out, 2 ms)"
      ].join("\n")
    assert_equal :red, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'three failing tests is red' do
    output =
      [
      "Errors (3 failures, 3 tests, 3 ran, 15 checks, 0 ignored, 0 filtered out, 4 ms)"
      ].join("\n")
    assert_equal :red, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'two passing tests is green' do
    output =
      [
      "OK (2 tests, 2 ran, 10 checks, 0 ignored, 0 filtered out, 1 ms)"
      ].join("\n")
    assert_equal :green, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'three passing tests is green' do
    output =
      [
      "OK (3 tests, 3 ran, 15 checks, 0 ignored, 0 filtered out, 1 ms)"
      ].join("\n")
    assert_equal :green, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'one failing test and one passing test is red' do
    output =
      [
      "Errors (1 failures, 2 tests, 2 ran, 10 checks, 0 ignored, 0 filtered out, 2 ms)"
      ].join("\n")
    assert_equal :red, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  test 'syntax error is amber' do
    output =
      [
      %q{TEST_Untitled_Create_Test::testBody()':},
      %q{UntitledTest.cpp:25:24: error: 'ssss' was not declared in this scope},
      %q{     FAIL("Start here");ssss},
      %q{                        ^},
      %q{compilation terminated due to -Wfatal-errors.},
      %q{make: *** [objs/UntitledTest.o] Error 1       }
      ].join("\n")
    assert_equal :amber, colour_of(output)
  end

  # - - - - - - - - - - - - - - -

  def colour_of(output)
    OutputParser::parse_cpputest(output)
  end

end
