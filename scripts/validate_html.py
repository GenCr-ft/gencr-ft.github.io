#!/usr/bin/env python3
# ===================================================================
# GenCr@ft Studio - Strict HTML Structural Validator v1.0
# ===================================================================
import sys
from html.parser import HTMLParser

class StrictHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tags_stack = []
        self.errors = []
        # Self-closing HTML tags that don't need a closing tag
        self.self_closing = {
            'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
            'link', 'meta', 'param', 'source', 'track', 'wbr'
        }

    def handle_starttag(self, tag, attrs):
        if tag not in self.self_closing:
            self.tags_stack.append((tag, self.getpos()))

    def handle_endtag(self, tag):
        if tag in self.self_closing:
            self.errors.append(f"Unnecessary closing tag </{tag}> at line {self.getpos()[0]}")
            return
        if not self.tags_stack:
            self.errors.append(f"Unexpected closing tag </{tag}> at line {self.getpos()[0]} (no open tags left)")
            return
        open_tag, pos = self.tags_stack.pop()
        if open_tag != tag:
            self.errors.append(f"Mismatched tag: opened <{open_tag}> at line {pos[0]}, but closed with </{tag}> at line {self.getpos()[0]}")
            # Put it back to keep tracking if possible
            self.tags_stack.append((open_tag, pos))

    def close(self):
        super().close()
        while self.tags_stack:
            open_tag, pos = self.tags_stack.pop()
            self.errors.append(f"Unclosed tag <{open_tag}> opened at line {pos[0]}")

def validate_file(filepath):
    parser = StrictHTMLParser()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        parser.feed(content)
        parser.close()
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        return False

    if parser.errors:
        print(f"❌ HTML Validation failed for {filepath}:")
        for err in parser.errors:
            print(f"  - {err}")
        return False
    print(f"✓ {filepath} is syntactically valid HTML.")
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 validate_html.py <path_to_html_file>")
        sys.exit(1)
    success = validate_file(sys.argv[1])
    sys.exit(0 if success else 1)
