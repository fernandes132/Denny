// Exercises the actual bundled player's JS bridge, not a parallel implementation.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const file = new URL('../Luma/Resources/YouTubePlayer.html', import.meta.url);
const html = fs.readFileSync(file, 'utf8').replaceAll('__VIDEO_ID__', 'aqz-KE-bpKQ').replaceAll('__ORIGIN__', 'https://nl.luma.pilot');
const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)][0]?.[1];
assert.ok(script, 'Bundled player bootstrap must exist');
const messages = [];
let config;
const context = vm.createContext({
  window: {webkit: {messageHandlers: {lumaPlayer: {postMessage: (message) => messages.push(message)}}}},
  YT: {Player: function (element, options) { assert.equal(element, 'player'); config = options; }}
});
vm.runInContext(script, context);
context.onYouTubeIframeAPIReady();
assert.equal(config.videoId, 'aqz-KE-bpKQ');
assert.equal(config.playerVars.origin, 'https://nl.luma.pilot');
assert.equal(config.playerVars.autoplay, 0, 'No autoplay before user action');
assert.equal(config.playerVars.controls, 1, 'Official controls remain enabled');
assert.equal(config.host, 'https://www.youtube-nocookie.com');
config.events.onReady();
assert.equal(messages.at(-1).event, 'ready');
for (const code of [100, 101, 150, 153]) {
  config.events.onError({data: code});
  assert.equal(messages.at(-1).event, 'error');
  assert.equal(messages.at(-1).code, code);
}
assert.match(html, /min-height:200px/, 'Minimum embedded viewport must be preserved');
assert.match(html, /strict-origin-when-cross-origin/);
console.log('PASS: actual player bootstrap, app origin, no autoplay, official controls, ready/error bridge, minimum viewport.');
