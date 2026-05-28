---
bc-version: [all]
domain: performance
keywords: [instream, outstream, length, stream, upload, blob, http, chunk]
technologies: [al]
countries: [w1]
application-area: [all]
---

# `InStream.Length` is unreliable for branching on payload size

## Description

`InStream` exposes a `Length` property that returns the total byte count of the underlying buffer when the runtime can determine it. The catch is that "when the runtime can determine it" depends on **how the stream was obtained**:

- Streams produced from a `Blob` or a `Temp Blob` field by `CreateInStream` — `Length` is reliable; the blob is fully materialised.
- Streams produced from a Media or MediaSet field — same: backed by a known-size payload.
- Streams produced from `HttpResponseMessage.Content.ReadAs` and from many `File.*` APIs — `Length` may return `0` or a partial value, because the underlying transport is consumed incrementally and the total length is not known until the stream is exhausted.
- Streams from `Stream` parameters supplied by callers — depends entirely on what the caller passed in.

Branching upload behaviour on `Stream.Length` is the common failure mode. The pattern is:

```al
if Stream.Length <= MaxSimpleUploadSize then
    UploadSimple(Stream)
else
    UploadChunked(Stream);
```

For a Microsoft Graph drive upload, `MaxSimpleUploadSize` is 4 MB. If `Stream.Length` returns `0` (because the stream came from an HTTP response or a freshly written outstream that the runtime cannot size cheaply), the code takes the simple-upload path with a 10 MB file behind it, the API returns `413 Payload Too Large`, and the upload fails. The error surfaces to the user as a generic HTTP failure with no obvious connection to the buggy size check.

The same trap applies to any code that "skips the work if the stream is empty": `if Stream.Length = 0 then exit;` silently drops payloads when the stream came from a source that does not pre-compute length.

## Best Practice

Decide which behaviour you actually need.

- **Always-chunked** is the safe default when the stream's origin is not under your control. Chunked uploads work for any payload size; the per-chunk overhead is small for small payloads.
- When a size threshold is genuinely required (for example, choosing between two endpoints with different cost profiles), copy the stream into a known-size buffer first — typically a `Temp Blob` — and read length from the blob, which IS reliable. The cost of one round-trip through a blob is acceptable for the upload-routing decision.
- When the threshold is informational (logging, telemetry), guard against `0`: `if (Stream.Length > 0) and (Stream.Length <= Threshold)` so an unknown size routes to the safe path, not the optimistic one.

See sample: `instream-length-unreliable-for-bc-streams.good.al`.

## Anti Pattern

Branching upload size, validation, or buffer allocation directly on `Stream.Length` when the stream's origin is anything other than a freshly-materialised blob. Detection signal: `Stream.Length` (or `.Length` on a variable typed `InStream` or `OutStream`) appearing as the left or right side of `<=`, `<`, `>=`, `>`, or `=` against a size-like constant or `Label`, with no prior copy through a `Blob`. The narrower signal — branching simple-vs-chunked upload on `Length` for Graph or REST endpoints with a documented size cap — is the high-confidence case.

See sample: `instream-length-unreliable-for-bc-streams.bad.al`.
