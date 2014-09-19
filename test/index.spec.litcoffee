Requirements
============

    fs     = require "fs"
    path   = require "path"
    assert = require "assert"
    {exec} = require "child_process"
    VOSCO  = require ".."

VOSCO
=====

This is a functionality test suite for VOSCO.

    describe "VOSCO", ->
      it "should setup repository"
      it "should give commit history"
      it "should give current status"
      it "should give file content history"
      it "should create a snapshot"
      it "should preview a snapshot"
      it "should rollback to a snapshot"
      it "should create new branch"
      it "should switch to a brach"
      it "should delete a branch"

Helpers
=======

    test_path = "/tmp/test_repo"
    test_opts =
      author_name: 'John Doe'
      author_email: 'john.doe@gmail.com'

    beforeEach (callback) ->
      test_file = path.resolve test_path, 'hello.txt'
      await exec "mkdir #{test_path}", defer()
      await exec "echo hello > #{test_file}", defer()
      callback null

    afterEach (callback) ->
      await exec "rm -rf #{test_path}", defer()
      callback null
