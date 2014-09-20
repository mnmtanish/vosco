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

    describe "VOSCO (Spec)", ->

Setup
=====

      it "should setup repository", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        contents = fs.readdirSync test_path
        assert.equal contents.indexOf('.vosco') >= 0, true
        callback null

Status
======

      it "should give current status", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await exec "echo 1 > #{test_file}-remove", defer()
        await exec "echo 2 > #{test_file}-edit", defer()
        await vosco.createSnapshot 'test', defer()
        await exec "rm #{test_file}-remove", defer()
        await exec "echo 3 > #{test_file}-edit", defer()
        await exec "echo 4 > #{test_file}-new", defer()
        await vosco.getStatus defer(err, out)
        assert.deepEqual out, [
          { type: "modified", path: "etc/hello.txt-edit" }
          { type: "removed", path: "etc/hello.txt-remove" }
          { type: "untracked", path: "etc/hello.txt-new" }]
        callback null

Snapshots
=========

      it "should give snapshot history", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.getHistory defer(err, out)
        initialCommit =
          hash: out[0].hash
          author: test_opts.author_name
          email: test_opts.author_email
          date: out[0].date
          message: 'Install VOSCO'
        assert.deepEqual out, [initialCommit]
        callback null

      it "should create a snapshot", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await exec "echo a > #{test_file}-new", defer()
        await vosco.createSnapshot 'test', defer()
        await vosco.getHistory defer(err, out)
        assert.equal out[0].message, 'test'
        callback null

      it "should preview a snapshot", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await exec "echo a > #{test_file}-new", defer()
        await vosco.createSnapshot 'test', defer()
        await vosco.getHistory defer(err, out)
        await vosco.previewSnapshot out[0].hash, defer(err, out)
        assert.equal out, """diff --git a/etc/hello.txt-new b/etc/hello.txt-new
        new file mode 100644
        index 0000000..7898192
        --- /dev/null
        +++ b/etc/hello.txt-new
        @@ -0,0 +1 @@
        +a

        """
        callback null

      it "should rollback to a snapshot", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await exec "echo a > #{test_file}-new", defer()
        await vosco.createSnapshot 'test', defer()
        await vosco.getHistory defer(err, out)
        await vosco.rollbackToSnapshot out[1].hash, defer()
        await vosco.getHistory defer(err, out)
        assert.equal out[0].message, 'Install VOSCO'
        callback null

Branches
========

      it "should show current branch", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.getBranches defer(error, branches, currentBranch)
        assert.equal currentBranch, 'master'
        callback null

      it "should list all branches", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.getBranches defer(error, branches, currentBranch)
        assert.deepEqual branches, ['master']
        callback null

      it "should create new branch", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.createBranch 'test', defer()
        await vosco.getBranches defer(error, branches, currentBranch)
        assert.equal currentBranch, 'test'
        assert.deepEqual branches, ['master', 'test']
        callback null

      it "should switch to a brach", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.createBranch 'test', defer()
        await vosco.selectBranch 'master', defer()
        await vosco.getBranches defer(error, branches, currentBranch)
        assert.equal currentBranch, 'master'
        assert.deepEqual branches, ['master', 'test']
        callback null

      it "should delete a branch", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await vosco.createBranch 'test', defer()
        await vosco.deleteBranch 'master', defer()
        await vosco.getBranches defer(error, branches, currentBranch)
        assert.equal currentBranch, 'test'
        assert.deepEqual branches, ['test']
        callback null

Content History
===============

      it "should give file content history", (callback) ->
        vosco = new VOSCO test_path, test_opts
        await vosco.install defer()
        await exec "echo world >> #{test_file}", defer()
        await vosco.createSnapshot 'test', defer()
        await vosco.getContentHistory 'etc/hello.txt', defer(err, out)
        assert.equal out.lines[1].code, 'hello'
        assert.equal out.commits[out.lines[1].hash].summary, 'Install VOSCO'
        assert.equal out.lines[2].code, 'world'
        assert.equal out.commits[out.lines[2].hash].summary, 'test'
        callback null

Helpers
=======

    test_path = "/tmp/test_repo"
    repo_path = "/tmp/test_repo/.vosco"
    test_file = path.resolve test_path, 'etc', 'hello.txt'
    test_opts =
      author_name: 'John Doe'
      author_email: 'john.doe@gmail.com'

    beforeEach (callback) ->
      await exec "mkdir #{test_path}", defer()
      await exec "mkdir #{test_path}/etc", defer()
      await exec "echo hello > #{test_file}", defer()
      callback null

    afterEach (callback) ->
      await exec "rm -rf #{test_path}", defer()
      callback null
