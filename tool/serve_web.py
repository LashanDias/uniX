"""Serve build/web for local testing, with caching switched off.

Flutter's release bundle ships a service worker and long-lived asset names, so
a plain static server lets the browser keep serving the previous build after a
rebuild -- the app looks unchanged, or worse, mixes old and new code. Every
response here carries no-store, so a plain refresh always picks up the latest
`flutter build web`.

Usage:
    python tool/serve_web.py [port]
"""

import functools
import http.server
import os
import sys

DEFAULT_PORT = 5123
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'web')


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def log_message(self, fmt, *args):
        # Quiet: one line per request drowns the console during a page load.
        pass


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    root = os.path.normpath(ROOT)
    if not os.path.isfile(os.path.join(root, 'index.html')):
        sys.exit(
            'No build found at %s.\n'
            'Run: flutter build web --release --no-wasm-dry-run' % root
        )
    handler = functools.partial(NoCacheHandler, directory=root)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', port), handler)
    print('Serving %s' % root)
    print('Open http://localhost:%d' % port)
    print('Caching is off, so a normal refresh shows the latest build.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nStopped.')


if __name__ == '__main__':
    main()
