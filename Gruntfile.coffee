module.exports = (grunt) ->
  grunt.initConfig

    nodeunit:
      files: ['test/**/*_test.coffee']

    watch:
      all:
        files: [
          'src/*.coffee'
          'test/*.coffee'
        ]
        tasks: ['nodeunit']

  grunt.loadNpmTasks task for task in [
    'grunt-contrib-nodeunit'
    'grunt-contrib-watch'
  ]

  grunt.registerTask 'default', ['watch:all']
