run cd native
  cd native
  cmake -S torrent_engine -B build/ios \
    -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DIOS=ON
  cmake --build build/ios --config Release
  cp build/ios/Release/libtorrent_engine.a ../ios/Runner/
  shell: /bin/bash -e {0}
  env:
    FLUTTER_VERSION: 3.29.2
    FLUTTER_ROOT: /Users/runner/hostedtoolcache/flutter/stable-3.29.2-arm64/flutter
    PUB_CACHE: /Users/runner/.pub-cache
  
-- The CXX compiler identification is AppleClang 17.0.0.17000013
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done (13.6s)
-- Generating done (0.0s)
-- Build files have been written to: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios
Command line invocation:
    /Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild -project torrent_engine.xcodeproj build -configuration Release -parallelizeTargets -hideShellScriptEnvironment -target ALL_BUILD
ComputePackagePrebuildTargetDependencyGraph
CreateBuildRequest
SendProjectDescription
CreateBuildOperation
ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (3 targets)
    Target 'ALL_BUILD' in project 'torrent_engine'
        ➜ Explicit dependency on target 'torrent_engine' in project 'torrent_engine'
        ➜ Explicit dependency on target 'ZERO_CHECK' in project 'torrent_engine'
    Target 'torrent_engine' in project 'torrent_engine'
        ➜ Explicit dependency on target 'ZERO_CHECK' in project 'torrent_engine'
    Target 'ZERO_CHECK' in project 'torrent_engine' (no dependencies)
GatherProvisioningInputs
CreateBuildDescription
ExecuteExternalTool /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -arch arm64 -isysroot /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -x c++ -c /dev/null
ExecuteExternalTool /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -x c -c /dev/null
ExecuteExternalTool /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool -V
Build description signature: 1f3a14d07d86ab35639fa07dc9eb445e
Build description path: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/XCBuildData/1f3a14d07d86ab35639fa07dc9eb445e.xcbuilddata
CreateBuildDirectory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/torrent_engine.xcodeproj
    builtin-create-build-directory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build
CreateBuildDirectory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/torrent_engine.xcodeproj
    builtin-create-build-directory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos
ClangStatCache /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/torrent_engine.xcodeproj
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -o /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache
CreateBuildDirectory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/Release-iphoneos
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/torrent_engine.xcodeproj
    builtin-create-build-directory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/Release-iphoneos
CreateBuildDirectory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/EagerLinkingTBDs/Release-iphoneos
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/torrent_engine.xcodeproj
    builtin-create-build-directory /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/EagerLinkingTBDs/Release-iphoneos
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ZERO_CHECK.build/Script-91EC1823C9D52F376007B7D7.sh (in target 'ZERO_CHECK' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ZERO_CHECK.build/Script-91EC1823C9D52F376007B7D7.sh
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ALL_BUILD.build/Script-6EBA7106EF35FBDC1C408935.sh (in target 'ALL_BUILD' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ALL_BUILD.build/Script-6EBA7106EF35FBDC1C408935.sh
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/torrent_engine.DependencyStaticMetadataFileList (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/torrent_engine.DependencyStaticMetadataFileList
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/torrent_engine.DependencyMetadataFileList (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/torrent_engine.DependencyMetadataFileList
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/torrent_engine.LinkFileList (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/torrent_engine.LinkFileList
WriteAuxiliaryFile /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    write-file /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
-target arm64-apple-ios16.0 -fpascal-strings -O3 '-DCMAKE_INTDIR="Release-iphoneos"' -isysroot /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -I/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos/include -I/Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/include -I/Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src -I/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/DerivedSources-normal/arm64 -I/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/DerivedSources/arm64 -I/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/DerivedSources -F/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos -DNDEBUG '-std=gnu++17'
PhaseScriptExecution Generate\ CMakeFiles/ZERO_CHECK /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ZERO_CHECK.build/Script-91EC1823C9D52F376007B7D7.sh (in target 'ZERO_CHECK' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    /bin/sh -c /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ZERO_CHECK.build/Script-91EC1823C9D52F376007B7D7.sh
make: `/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/CMakeFiles/cmake.check_cache' is up to date.
CompileC /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/torrent_engine.o /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/torrent_engine.cpp normal arm64 c++ com.apple.compilers.llvm.clang.1_0.compiler (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    
    Using response file: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
    
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x c++ -ivfsstatcache /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -fmessage-length\=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit\=0 -fno-color-diagnostics -Wno-trigraphs -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-non-virtual-dtor -Wno-overloaded-virtual -Wno-exit-time-destructors -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wno-newline-eo
/Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/torrent_engine.cpp:27:53: warning: implicit conversion loses integer precision: 'size_type' (aka 'unsigned long') to 'int' [-Wshorten-64-to-32]
   27 |       out->piece_count = pieces->str_val().length() / 20;
      |                        ~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~
1 warning generated.
CompileC /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/sha1.o /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/sha1.cpp normal arm64 c++ com.apple.compilers.llvm.clang.1_0.compiler (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    
    Using response file: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
    
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x c++ -ivfsstatcache /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -fmessage-length\=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit\=0 -fno-color-diagnostics -Wno-trigraphs -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-non-virtual-dtor -Wno-overloaded-virtual -Wno-exit-time-destructors -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wno-newline-eo
CompileC /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/piece_manager.o /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/piece_manager.cpp normal arm64 c++ com.apple.compilers.llvm.clang.1_0.compiler (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    
    Using response file: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
    
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x c++ -ivfsstatcache /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -fmessage-length\=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit\=0 -fno-color-diagnostics -Wno-trigraphs -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-non-virtual-dtor -Wno-overloaded-virtual -Wno-exit-time-destructors -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wno-newline-eo
/Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/piece_manager.cpp:9:50: warning: implicit conversion loses integer precision: 'int64_t' (aka 'long long') to 'int' [-Wshorten-64-to-32]
    9 |   piece_count_ = (total_size_ + piece_size_ - 1) / piece_size_;
      |                ~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~
/Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/piece_manager.cpp:10:54: warning: implicit conversion loses integer precision: 'int64_t' (aka 'long long') to 'int' [-Wshorten-64-to-32]
   10 |   blocks_per_piece_ = (piece_size_ + BLOCK_SIZE - 1) / BLOCK_SIZE;
      |                     ~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~
2 warnings generated.
CompileC /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/magnet_uri.o /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/magnet_uri.cpp normal arm64 c++ com.apple.compilers.llvm.clang.1_0.compiler (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    
    Using response file: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
    
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x c++ -ivfsstatcache /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -fmessage-length\=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit\=0 -fno-color-diagnostics -Wno-trigraphs -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-non-virtual-dtor -Wno-overloaded-virtual -Wno-exit-time-destructors -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wno-newline-eo
CompileC /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/bencode.o /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine/src/bencode.cpp normal arm64 c++ com.apple.compilers.llvm.clang.1_0.compiler (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    
    Using response file: /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/82b82416624d2658e5098eb0a28c15c5-common-args.resp
    
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x c++ -ivfsstatcache /var/folders/mn/js5hmsy13552y330w_94s79h0000gn/C/com.apple.DeveloperTools/16.4-16F6/Xcode/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -fmessage-length\=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit\=0 -fno-color-diagnostics -Wno-trigraphs -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-non-virtual-dtor -Wno-overloaded-virtual -Wno-exit-time-destructors -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wno-newline-eo
Libtool /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos/libtorrent_engine.a normal (in target 'torrent_engine' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool -static -arch_only arm64 -D -syslibroot /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -L/Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos -filelist /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/torrent_engine.LinkFileList -dependency_info /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/Objects-normal/arm64/torrent_engine_libtool_dependency_info.dat -o /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/Release-iphoneos/libtorrent_engine.a
PhaseScriptExecution Generate\ CMakeFiles/ALL_BUILD /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ALL_BUILD.build/Script-6EBA7106EF35FBDC1C408935.sh (in target 'ALL_BUILD' from project 'torrent_engine')
    cd /Users/runner/work/TorrentSearch/TorrentSearch/native/torrent_engine
    /bin/sh -c /Users/runner/work/TorrentSearch/TorrentSearch/native/build/ios/build/torrent_engine.build/Release-iphoneos/ALL_BUILD.build/Script-6EBA7106EF35FBDC1C408935.sh
Build all projects
note: Run script build phase 'Generate CMakeFiles/ZERO_CHECK' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'ZERO_CHECK' from project 'torrent_engine')
note: Run script build phase 'Generate CMakeFiles/ALL_BUILD' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'ALL_BUILD' from project 'torrent_engine')
** BUILD SUCCEEDED **
cp: build/ios/Release/libtorrent_engine.a: No such file or directory
Error: Process completed with exit code 1.