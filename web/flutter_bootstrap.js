// Use CanvasKit for consistent font and emoji rendering across browsers.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    renderer: 'canvaskit',
    useColorEmoji: false,
  },
});
