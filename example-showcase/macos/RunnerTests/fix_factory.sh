#!/bin/bash

# Replace all factory.create calls to remove withFrame parameter
perl -i -0pe 's/factory\.create\(\s*withFrame:\s*[^,]+,\s*viewIdentifier:/factory.create(withViewIdentifier:/gs' VideoPlayerViewFactoryTests.swift

# Remove .view() calls since we get NSView directly
perl -i -pe 's/\.view\(\)//' VideoPlayerViewFactoryTests.swift

# Remove PlayerContainerView tests (lines 336-383)
sed -i '' '336,383d' VideoPlayerViewFactoryTests.swift

echo "Fixed VideoPlayerViewFactoryTests.swift"
