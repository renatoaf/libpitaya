ANDROID_TOOLCHAIN_FILE = ../temp/android-ndk-r17b/build/cmake/android.toolchain.cmake

setup-mac:
	@brew install ninja

setup-android:
	@mkdir -p temp
	@curl https://dl.google.com/android/repository/android-ndk-r17b-darwin-x86_64.zip -o temp/android-ndk-r17b.zip
	@unzip -qo temp/android-ndk-r17b.zip -d temp/

setup-android-linux:
	@mkdir -p temp
	@curl https://dl.google.com/android/repository/android-ndk-r17b-linux-x86_64.zip -o temp/android-ndk-r17b.zip
	@unzip -qo temp/android-ndk-r17b.zip -d temp/

setup-go:
	@sudo rm -rf ~/.gimme
	@gimme 1.10.2
	@gimme list
	@echo Go installed version $(shell go version)

setup-go-linux:
	@mkdir -p ~/bin
	@curl https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz -o ~/bin/go1.10.3.linux-amd64.tar.gz
	@cd ~/bin && tar xf ~/bin/go1.10.3.linux-amd64.tar.gz
	@~/bin/go/bin/go version

setup-go-mac:
	@mkdir -p ~/bin
	@curl https://dl.google.com/go/go1.10.3.darwin-amd64.tar.gz -o ~/bin/go1.10.3.darwin-amd64.tar.gz
	@cd ~/bin && tar xf ~/bin/go1.10.3.darwin-amd64.tar.gz

setup-node-linux:
	@curl https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.xz -o ~/node-v8.11.3-linux-x64.tar.xz
	@cd ~ && tar xf ~/node-v8.11.3-linux-x64.tar.xz && mv ~/node-v8.11.3-linux-x64 ~/node

setup-node-mac:
	@curl https://nodejs.org/dist/v8.11.3/node-v8.11.3-darwin-x64.tar.xz -o ~/node-v8.11.3-darwin-x64.tar.xz
	@cd ~ && tar xf ~/node-v8.11.3-darwin-x64.tar.xz

build-android:
	@rm -rf _builds/android
	@cmake -GNinja -H. -B_builds/android -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release \
				   -DCMAKE_TOOLCHAIN_FILE=${ANDROID_TOOLCHAIN_FILE} \
				   -DANDROID_ABI=armeabi-v7a
	@cmake --build _builds/android

build-mac:
	@rm -rf _builds/mac
	@cmake -H. -B_builds/mac -GNinja -DCMAKE_BUILD_TYPE=Release
	@cmake --build _builds/mac

build-linux:
	@rm -rf _builds/linux
	@cmake -H. -B_builds/linux -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
	@cmake --build _builds/linux

build-ios:
	@rm -rf _builds/ios
	@cmake -H. -B_builds/ios -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=../../cmake/ios.toolchain.cmake
	@cmake --build _builds/ios

clean-docker-container:
	@if [[ `docker ps -aqf "name=libpitaya"` != "" ]]; then \
		docker rm `docker ps -aqf "name=libpitaya"` ; \
	fi

build-linux-docker: clean-docker-container
	@docker build -t libpitaya .
	@docker run --name libpitaya libpitaya:latest
	@mkdir -p _builds/linux
	@docker cp `docker ps -aqf "name=libpitaya"`:/app/_builds/linux/libpitaya-linux.so _builds/linux
	@$(MAKE) clean-docker-container

.PHONY: build

test-deps: setup-node setup-go
	@-(cd test/server && go get)

build:
	cmake --build build

test: build test-deps
	./run-tests.sh

create-out-folder:
	@rm -r out
	@mkdir -p out

build-servers-linux: create-out-folder
	@cd pitaya-servers/json-server && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ../../out/json_server_linux
	@cd pitaya-servers/protobuf-server && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ../../out/protobuf_server_linux

docker-build: build-servers-linux
	@docker build -t libpitaya-test-servers .
