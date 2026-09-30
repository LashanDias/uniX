// CanvasKit for consistent text rendering, with the colour emoji font loaded.
// With useColorEmoji off, CanvasKit falls back to whatever the system
// provides, and emoji the system lacks render as empty boxes -- the wave in
// "Welcome!" on the login screen did exactly that.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    renderer: 'canvaskit',
    useColorEmoji: true,
  },
});
