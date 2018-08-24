Pod::Spec.new do |s|
  s.name                  = 'SparkLib'
  # in case of manual version bump update SparkPlayer.podspec s.dependency
  s.version               = '1.3.2.spark.1.106.19'
  s.summary               = 'SparkLib integration SDK'
  s.description      = <<-DESC
Integrate favorite SparkLib features in your iOS apps
                       DESC

  s.homepage              = 'https://holaspark.com'
  s.license               = { :type => 'holaspark.com' }
  s.author                = 'holaspark.com'
  s.source                = {
    :git => 'https://github.com/spark-mv/ios_sdk.git',
    :tag => 'v1.106.19'
  }

  s.ios.deployment_target = '8.0'

  s.vendored_frameworks    = 'lib/dist/SparkLib.framework'
end
