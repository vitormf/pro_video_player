import re

with open('VideoPlayerViewFactoryTests.swift', 'r') as f:
    content = f.read()

# Replace factory.create calls - remove withFrame parameter
pattern = r'factory\.create\(\s*withFrame:\s*[^,]+,\s*viewIdentifier:'
replacement = 'factory.create(withViewIdentifier:'
content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)

# Remove .view() calls
content = content.replace('.view()', '')

with open('VideoPlayerViewFactoryTests.swift', 'w') as f:
    f.write(content)

print("Fixed all factory.create calls and .view() references")
