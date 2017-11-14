Pod::Spec.new do |s|
    s.name = 'CacheTracker'
    s.version = '1.0.0'
    s.summary = 'Helper to divide UI from Database layer. Based on https://github.com/akantsevoi/CacheTracker'
    s.homepage = 'https://github.com/ladeiko/CacheTracker'
    s.license = { :type => 'CUSTOM', :file => 'LICENSE' }
    s.author = { 'Siarhei Ladzeika' => 'sergey.ladeiko@gmail.com' }
    s.platform = :ios, '9.0'
    s.source = { :git => 'https://github.com/ladeiko/CacheTracker.git', :tag => "#{s.version}" }
    s.source_files = 'Classes/Core/**/*.{swift}'
    s.requires_arc = true
    s.default_subspec = 'Lite'

    s.subspec 'Lite' do |s|
        # subspec for users who don't want the CoreData/Realm
        s.source_files = 'Classes/Core/**/*.{swift}'
    end

    s.subspec 'CoreData' do |s|
        s.source_files = 'Classes/CoreData/**/*.{swift}'
        s.frameworks = 'CoreData'
    end

    s.subspec 'Realm' do |s|
        s.source_files = 'Classes/Realm/**/*.{swift}'
        s.dependency 'RBQFetchedResultsControllerX'
        s.dependency 'SafeRealmObject'
    end

end