require 'test_helper'
require 'lib/worker'

describe Worker do

  # simple test for syntax errors
  it "should init with a task block, start and stop threads" do
    w = Worker.new {|item| item }
    w.start
    w.stop
  end

  it "should enqueue and perform tasks" do
    # Use something mutable to test side effects
    a = {n:1}
    b = {n:2}
    c = {n:3}
    w = Worker.new(items:[a,b,c]){|h| h[:n] += 2 }

    # Worker shouldn't have started yet
    assert_equal 1, a[:n]
    assert_equal 2, b[:n]
    assert_equal 3, c[:n]

    # Let worker do its thing
    w.start
    sleep 0.1 #this is arbitrary but plenty of time for adding two numbers
    d = {n:4}
    w.enqueue(d)
    sleep 0.1

    # All mutations should be done
    assert_equal 3, a[:n]
    assert_equal 4, b[:n]
    assert_equal 5, c[:n]
    assert_equal 6, d[:n]
  end

end
