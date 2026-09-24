DERIVED := build
TEAM := 996Y4MJA7D
HAS_TEAM_IDENTITY := $(shell security find-identity -v -p codesigning 2>/dev/null | grep -q "($(TEAM))" && echo yes)
ADHOC_SIGNING := CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER=
SIGNING := $(if $(HAS_TEAM_IDENTITY),,$(ADHOC_SIGNING))
XCB := xcodebuild -project Jelly.xcodeproj -scheme Jelly -derivedDataPath $(DERIVED) -skipPackagePluginValidation $(SIGNING)

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
	-pkill -f "Jelly \\(Debug\\)\\.app/Contents/MacOS"

clean:
	rm -rf $(DERIVED)
