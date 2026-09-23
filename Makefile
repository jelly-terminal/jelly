DERIVED := build
XCB := xcodebuild -project Jelly.xcodeproj -scheme Jelly -derivedDataPath $(DERIVED) -skipPackagePluginValidation

.PHONY: debug prod build test kill clean

build:
	$(XCB) -configuration Debug build

debug: build
	open "$(DERIVED)/Build/Products/Debug/Jelly (Debug).app"

prod:
	$(XCB) -configuration Release build
	open "$(DERIVED)/Build/Products/Release/Jelly.app"

test:
	cd Packages/JellyCore && swift test
	cd Packages/JellyTerminal && swift test

kill:
	-pkill -x Jelly
	-pkill -f "Jelly (Debug).app/Contents/MacOS"

clean:
	rm -rf $(DERIVED)
