VOSCO
=====

Dependencies
------------

    path   = require "path"
    VOSCO  = require ".."

Constructor
-----------

    describe 'VOSCO::constructor', ->
      it "should set environment variables"

Setup
-----

    describe 'VOSCO::install', ->
      it "should create the repo"
      it "should create initial snapshot"

Repository
----------

    describe 'VOSCO::getRepositoryPath', ->
      it "should return vosco repo path"

    describe 'VOSCO::createRepository', ->
      it "should create repo with template"

    describe 'VOSCO::getHistory', ->
      it "should give snapshot history"

Information
-----------

    describe 'VOSCO::getStatus', ->
      it "should give current status of repo"

    describe 'VOSCO::getBlameInfo', ->
      it "should give blame info for a given file"

Snapshot
--------

    describe 'VOSCO::createSnapshot', ->
      it "should create a new snapshot"

    describe 'VOSCO::rollbackToSnapshot', ->
      it "should rollback to an older snapshot"

Branch
------

    describe 'VOSCO::createBranch', ->
      it "should create a new branch"

    describe 'VOSCO::selectBranch', ->
      it "should witch to a branch"

    describe 'VOSCO::deleteBranch', ->
      it "should delete a branch"

Helpers
-------

    describe 'VOSCO::_getEnvironmentVariables', ->
      it "should return environment variables"

    describe 'VOSCO::_getTemplatePath', ->
      it "should return template path"

    describe 'VOSCO::_getLogFormat', ->
      it "should return JSON log format"

    describe 'VOSCO::_runGitCommand', ->
      it "should run a command with git"

Helpers (parsers)
-----------------

    describe 'VOSCO::_parseLogOutput', ->
      it "should parse and return log output"

    describe 'VOSCO::_parseBlameOutput', ->
      it "should parse and return blame output"
