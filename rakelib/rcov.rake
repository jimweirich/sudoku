begin
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << "test"
    dot_rakes = 
    t.rcov_opts = [
      '-xRakefile', '-xrakefile', '-xpublish.rf',
      '-xlib/rake/contrib', '-x/Library', "-x#{ENV['HOME']}/.gem",
      '--text-report',
      '--sort coverage'
    ] + FileList['rakelib/*.rake'].pathmap("-x%p")
    t.test_files = FileList[
      '*_test.rb',                      
      'test/lib/*_test.rb',
      'test/contrib/*_test.rb',
      'test/functional/*_test.rb'
    ]
    t.output_dir = 'coverage'
    t.verbose = true
  end
rescue LoadError
  puts "RCov is not available"
end
