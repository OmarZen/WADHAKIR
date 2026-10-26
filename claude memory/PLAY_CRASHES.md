# Google Play crash log

Crash clusters from Play Console → Android vitals → Crashes and ANRs, pasted
one at a time, with the diagnosis and status of each. Newest release first.
Release builds come from CI on **Flutter 3.44.4** (engine `a10d8ac3…`);
libflutter.so BuildId in the 3.4.3 traces: `fdf0a0a6f673cdcfc6c0e5f8dc7c8828d63fb3b6`.

## Summary (as of 2026-10-25, release 3.4.3+26)

| # | Cluster | Share | Cause | Status |
| --- | --- | --- | --- | --- |
| 1 | `libflutter.so OUTLINED_FUNCTION_7958` (arm64) | 56.3% · 65 users · 274 events | Same as #2: offscreen snapshot with no surface → Impeller GLES | Fixed (OnscreenGate), unreleased |
| 2 | `libflutter.so OUTLINED_FUNCTION_1033` (arm64) | 4.1% · 12 users | Same stack as #1 | Fixed (OnscreenGate), unreleased |
| 3 | `impeller::DeviceBufferGLES::OnGetContents` (armeabi_v7a) | 3.9% · 5 users | No trace from Play, but `OnGetContents` is the very call that faults in #1 (see emulator repro) | Very likely fixed with #1 |
| 4 | `impeller::BlitCopyBufferToTextureCommandGLES::Encode` (armeabi_v7a) | — | The function #1/#2 die in, on 32-bit (no outlining there, so it is the top frame). Trace not sent yet | Very likely fixed with #1 |
| 5 | `FloatingDhikrService.startInForeground` ForegroundServiceStartNotAllowedException | 22.2% · 10 users | Sticky restart from the background refused on Android 12+/15+ | Fixed, unreleased |
| 6 | `ConnectivityBroadcastReceiver.onCancel` IllegalArgumentException | 4.9% · 3.3.2 only | connectivity_plus 7.1.1 bug | Already fixed by 7.3.1 since 3.4.1 |

## #1 / #2 — Impeller GLES snapshot surface (the top crash)

**Stack (both samples identical from frame #01 down):**
`Picture::DoRasterizeToImage` → `Rasterizer::MakeImpellerSnapshot` →
`SnapshotControllerImpeller::MakeImpellerSnapshot` → `DoMakeRasterSnapshot` →
`AndroidSurfaceGLImpeller::CreateSnapshotSurface` →
`make_unique<GPUSurfaceGLImpeller>` → `make_shared<AiksContext>` →
`ContentContext::ContentContext` → `BlitPassGLES::EncodeCommands` →
`ReactorGLES::React` → `BlitCopyBufferToTextureCommandGLES::Encode` → SIGSEGV.

**What it means.** A `toImage` ran while the rasterizer had **no surface**.
In 3.44.4 `DoMakeRasterSnapshot` (shell/common/snapshot_controller_impeller.cc)
only calls `CreateSnapshotSurface` when `delegate.GetSurface()` is null. That
builds a throwaway pbuffer GL surface plus a brand-new AiksContext, and the
ContentContext constructor's first buffer→texture upload crashes on these GLES
drivers. With a surface, the existing context is reused and none of this runs.

**Who calls `toImage` without a surface.** `GlassPrayerHomeWidget.updateGlassWidgets`
→ home_widget 0.10.0 `renderFlutterWidget` (offscreen `RenderView` →
`repaintBoundary.toImage` → `toByteData`). It runs from:

- `PrayerTimesCubit._initialLoad` (constructor): the first load, and again
  after the GPS refresh (`refreshLocation` → `refreshSilently`), which can land
  seconds later, after the user has left;
- `main()` running headless for audio_service (`AudioServicePlugin.java:110`
  executes the default entrypoint when the media service is bound without an
  activity, e.g. media resumption after a reboot);
- the resume hook, which can beat the surface's re-creation.

**Devices.** Redmi Note 13 (Android 14), Samsung Galaxy A12 (MediaTek Helio
P35, Android 12). Both on Impeller GLES — Vulkan skipped (MediaTek < API 32) or
unavailable.

**Engine fixes checked (3.44.4 → 3.47.7).** #187404 (clear EGL context on
MediaTek) only covers API ≤ 29 MT6762/MT6765. #187932 (DeviceBufferGLES
dirty-range race) is a different bug. Upgrading Flutter alone does not fix this.

**Fix.** `lib/core/app/onscreen_gate.dart`: the glass render waits for a
`FrameTiming`, which the engine reports only for a frame it rasterized onto a
surface (`Rasterizer::DoDraw` returns `kNotSetUp` before `OnFrameRasterized`
when there is none). Not on screen → the newest model is deferred and rendered
the next time the app is.

Trade-off, accepted: glass widgets no longer re-render in the background on
any device (Dart cannot tell GLES from Vulkan), so a midnight or late-GPS
refresh waits for the next time the app is opened. On GLES phones that
background render used to crash the process instead.

Review follow-ups applied: timings for frames rasterized before the latest
resume are ignored (a batch from the old surface could land after a quick
leave-and-return), and a render interrupted mid-pair re-defers only when no
newer model is waiting.

**Reproduced on the emulator (2026-10-25).** Pixel_10 AVD (API 37) runs
"Impeller rendering backend (OpenGLES)". A temporary hook that called
`HomeWidget.renderFlutterWidget` 3 s after `paused` crashed every time:
SIGSEGV SEGV_MAPERR at 0x0 on `1.raster`. Symbolicated with the engine's
symbols.zip (local Flutter 3.47.7, engine `deb287481e…`):
`#00 Allocation::GetBuffer` (allocation.cc:21) ← `#01
BlitCopyBufferToTextureCommandGLES::Encode` (blit_command_gles.cc:209,
`source.GetBuffer()->OnGetContents()`) ← … ← `ContentContext` ← `AiksContext`
← `GPUSurfaceGLImpeller` ← `CreateSnapshotSurface` ← `DoMakeRasterSnapshot`.
Same stack as Play, and `OnGetContents` is #3's top frame. With the gate, the
same hook logged `onscreen=false` in the background, did not crash, and
rendered on the next return to the app (three cycles, same pid).

**Why the outlined name.** In release, `DeviceBufferGLES::OnGetContents` and
`Allocation::GetBuffer` are inlined and the machine outliner folds the load
into `OUTLINED_FUNCTION_N`; on armeabi_v7a (no outliner) the inlined frame
still shows as `OnGetContents`.

**Other snapshot paths checked (none unattended).** Share / Islamic-backgrounds
capture (`widget_to_image.dart`) runs on a tap after two `endOfFrame`s, which
stop while hidden. flutter_confetti's `Picture.toImage` is only for Emoji
particles (unused), vector_graphics' `toImageSync` only for SVG `<pattern>`
(none in the app). Image decoding uses the IO context, not
`CreateSnapshotSurface`.

### Raw trace — sample 1 (#1 OUTLINED_FUNCTION_7958)

Redmi Redmi Note 13 · Android 14 (SDK 34) · 26 (3.4.3)

```text
pid: 0, tid: 26264 >>> com.bloom.wadhakir <<<
backtrace:
 #00 pc 0x0000000000ab82d0 split_config.arm64_v8a.apk!libflutter.so (OUTLINED_FUNCTION_7958+14876672)
 #01 pc 0x000000000083b7ec libflutter.so (impeller::BlitCopyBufferToTextureCommandGLES::Encode(impeller::ReactorGLES const&) const+14876672)
 #02 pc 0x000000000083c3a0 libflutter.so (impeller::BlitPassGLES::EncodeCommands() const::$_0 ... operator()(impeller::ReactorGLES const&)+14876672)
 #03 pc 0x00000000008456a4 libflutter.so (impeller::ReactorGLES::React()+14876672)
 #04 pc 0x0000000000844f90 libflutter.so (impeller::ReactorGLES::AddOperation(std::__fl::function<void (impeller::ReactorGLES const&)>, bool)+14876672)
 #05 pc 0x000000000083bfe4 libflutter.so (impeller::BlitPassGLES::EncodeCommands() const+14876672)
 #06 pc 0x0000000000816a64 libflutter.so (impeller::ContentContext::ContentContext(shared_ptr<Context>, shared_ptr<TypographerContext>, shared_ptr<RenderTargetAllocator>)+14876672)
 #07 pc 0x000000000087efdc libflutter.so (std::__fl::make_shared<impeller::AiksContext, ...>+14876672)
 #08 pc 0x00000000004e641c libflutter.so (std::__fl::make_unique<flutter::GPUSurfaceGLImpeller, flutter::AndroidSurfaceGLImpeller*, ...>+14876672)
 #09 pc 0x00000000004e6290 libflutter.so (flutter::AndroidSurfaceGLImpeller::CreateSnapshotSurface()+14876672)
 #10 pc 0x00000000008941cc libflutter.so (flutter::(anonymous namespace)::DoMakeRasterSnapshot(sk_sp<DisplayList> const&, TSize<int>, SnapshotController::Delegate const&, SnapshotPixelFormat)+14876672)
 #11 pc 0x0000000000894150 libflutter.so (SnapshotControllerImpeller::MakeImpellerSnapshot(...)::$_1 ... operator()()+14876672)
 #12 pc 0x000000000050e5e0 libflutter.so (fml::SyncSwitch::Execute(fml::SyncSwitch::Handlers const&) const+14876672)
 #13 pc 0x00000000008940d4 libflutter.so (flutter::SnapshotControllerImpeller::MakeImpellerSnapshot(...)+14876672)
 #14 pc 0x000000000087eafc libflutter.so (flutter::Rasterizer::MakeImpellerSnapshot(...)+14876672)
 #15 pc 0x00000000008b0824 libflutter.so (fml::internal::CopyableLambda<flutter::Picture::DoRasterizeToImage(sk_sp<DisplayList> const&, unique_ptr<LayerTree>, unsigned int, unsigned int, _Dart_Handle*)::$_1> ... operator()()+14876672)
 #16 pc 0x000000000050d25c libflutter.so (fml::MessageLoopImpl::RunExpiredTasksNow()+14876672)
 #17 pc 0x0000000000511168 libflutter.so (fml::MessageLoopAndroid::MessageLoopAndroid()::$_0::__invoke(int, int, void*)+14876672)
 #18 pc 0x0000000000018e68 /system/lib64/libutils.so (android::Looper::pollInner(int)+1252)
 #19 pc 0x0000000000018920 /system/lib64/libutils.so (android::Looper::pollOnce(int, int*, int*, void**)+124)
 #20 pc 0x000000000001a188 /system/lib64/libandroid.so (ALooper_pollOnce+104)
 #21 pc 0x000000000051126c libflutter.so (fml::MessageLoopAndroid::Run()+14876672)
 #22 pc 0x000000000050f1a8 libflutter.so (fml::Thread::Thread(...)::$_0 ... operator()()+14876672)
 #23 pc 0x000000000050efb8 libflutter.so (fml::ThreadHandle::ThreadHandle(std::__fl::function<void ()>&&)::$_0::__invoke(void*)+14876672)
 #24 pc 0x00000000000fd528 /apex/com.android.runtime/lib64/bionic/libc.so (__pthread_start(void*)+208)
 #25 pc 0x0000000000096b24 /apex/com.android.runtime/lib64/bionic/libc.so (__start_thread+68)
(BuildId: fdf0a0a6f673cdcfc6c0e5f8dc7c8828d63fb3b6 for every libflutter.so frame)
```

### Raw trace — sample 2 (#2 OUTLINED_FUNCTION_1033)

Samsung Galaxy A12 · Android 12 (SDK 31) · 26 (3.4.3)

```text
pid: 0, tid: 13254 >>> com.bloom.wadhakir <<<
backtrace:
 #00 pc 0x0000000000a9ce00 split_config.arm64_v8a.apk!libflutter.so (OUTLINED_FUNCTION_1033)
 #01 pc 0x000000000083b7ec libflutter.so (impeller::BlitCopyBufferToTextureCommandGLES::Encode(impeller::ReactorGLES const&) const)
 #02 … #25 identical to sample 1 (same pcs, same functions), down to
       __pthread_start / __start_thread in libc.so
(BuildId: fdf0a0a6f673cdcfc6c0e5f8dc7c8828d63fb3b6)
```

## #3 — impeller::DeviceBufferGLES::OnGetContents (armeabi_v7a)

Infinix SMART 9 · Android 14 (SDK 34) · 26 (3.4.3) · **Play: "Stack trace not
available"**.

`OnGetContents` (3.44.4 device_buffer_gles.cc:30) is `return
backing_store_->GetBuffer()` guarded by `reactor_`, so a SIGSEGV inside it means
a dead or half-built DeviceBuffer. It sits on the same GLES upload path as #1,
so the gate most likely covers it too. Watch whether it disappears in the next
release; if it doesn't, look at other Play samples for a trace.

## #5 — FloatingDhikrService.startInForeground

ForegroundServiceStartNotAllowedException. A START_STICKY restart after process
death calls startForeground from the background; Android 12+ refuses, and from
Android 15 SYSTEM_ALERT_WINDOW only exempts an app with an overlay on screen.
Fix: startInForeground returns false on refusal → stop, START_NOT_STICKY; the
null-intent restart also stops when the feature is off (a preview had started
it); stopSelf(startId).

## #6 — ConnectivityBroadcastReceiver.onCancel

connectivity_plus 7.1.1 (shipped in 3.3.2) called `unregisterNetworkCallback`
unguarded. 7.3.1 (since 3.4.1) wraps it in try/catch. Only users still on 3.3.2.
