#!/usr/bin/env python3
"""extract_prompts.py — pull the copy-paste prompt blocks out of the workshop HTML.

The BwG-track2 module pages (m0.html ... m5.html) hold each hands-on prompt in a
`prompt-block` or `agent-ctx` div. This extracts them, in document order, to a JSON
the driver reads:  { "m0": [ {"id","cls","text"}, ... ], "m1": [...], ... }

Usage:
  python3 extract_prompts.py /path/to/BwG-track2 /tmp/agy-prompts/all.json
Then drive a step with its block id, e.g.:  ./drive.sh m0 ctx-combined m0s2
"""
import re, html, os, json, sys
from html.parser import HTMLParser


class Extract(HTMLParser):
    def __init__(self):
        super().__init__()
        self.capture = False; self.depth = 0; self.buf = []
        self.cur_id = None; self.cls = None; self.results = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs); cls = a.get('class', '')
        if not self.capture and ('prompt-block' in cls or ('agent-ctx' in cls and 'label' not in cls)):
            self.capture = True; self.depth = 1; self.buf = []
            self.cur_id = a.get('id', ''); self.cls = cls; return
        if self.capture:
            self.depth += 1

    def handle_endtag(self, tag):
        if self.capture:
            self.depth -= 1
            if self.depth == 0:
                text = html.unescape(''.join(self.buf))
                text = re.sub(r'[ \t]+', ' ', text)
                text = re.sub(r'\n\s*\n+', '\n', text).strip()
                text = re.sub(r'^(Copy)?\s*(prompt|tree|gemini enterprise|Paste into AGY|shell|terminal)?\s*',
                              '', text, flags=re.I)
                if text:
                    self.results.append((self.cur_id, self.cls.split()[0], text))
                self.capture = False

    def handle_data(self, data):
        if self.capture:
            self.buf.append(data)


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else '.'
    out_path = sys.argv[2] if len(sys.argv) > 2 else '/tmp/agy-prompts/all.json'
    out = {}
    for mod in ['m0', 'm1', 'm2', 'm3', 'm4', 'm5']:
        p = Extract()
        p.feed(open(os.path.join(src, mod + '.html')).read())
        out[mod] = [{'id': cid, 'cls': cls, 'text': t} for cid, cls, t in p.results]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    json.dump(out, open(out_path, 'w'), indent=2)
    for mod in out:
        print(mod, [(b['id'], len(b['text'])) for b in out[mod]])
    print('wrote', out_path)


if __name__ == '__main__':
    main()
