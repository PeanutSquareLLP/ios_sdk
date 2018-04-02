Pod::Spec.new do |s|
  s.name             = 'SparkPlayer'
  s.version          = '1.0.1-spark.1.89.960'
  s.summary          = 'Spark video player'

  s.description      = <<-DESC
Spark video player.
                       DESC

  s.homepage         = 'https://holaspark.com'
  s.license          = { :type => 'holaspark.com' }
  s.author           = 'holaspark.com'
  s.source           = {
    :git => 'https://github.com/hola/spark_ios_sdk.git',
    :tag => 'v1.89.960'
  }

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'

  s.source_files          = 'player/SparkPlayer/Classes/**/*.{swift,h,m}'

  s.resource_bundles = {
    'SparkPlayer' => ['player/SparkPlayer/Assets/*']
  }

  s.frameworks = 'UIKit', 'AVKit', 'AVFoundation'
  s.dependency 'SparkLib', '~> 1.3'
  s.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.7'
end
