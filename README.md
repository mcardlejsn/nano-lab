# Nano Lab

Nano Lab is an Android-only Flutter experiment for evaluating Google's Gemini Nano through controlled, repeatable tests on real devices.

It asks one central question:

> What can Gemini Nano reliably do on-device, what are its important limitations, and which practical uses are appropriate or inappropriate?

Nano Lab is an independent learning and evaluation project. It is not a production application, a medical tool, or a Google product.

## Current status

The Pixel 10 Pro evaluation is complete. It covers:

- Freeform Prompt API behavior and generation controls
- Deterministic sorting and structured extraction
- Dedicated Summarization, Rewriting, and Proofreading APIs
- Image Description with synthetic and real images
- Advanced GenAI Speech Recognition
- Model and feature-adapter availability and downloads
- Airplane-mode operation after all assets are installed
- Release APK permission verification

A controlled Pixel 11 Pro XL comparison will be added after that device becomes available.

Read the complete methodology, measurements, outputs, limitations, and conclusions in [NANO_LAB_FINDINGS.md](NANO_LAB_FINDINGS.md).

## Why this project exists

Gemini Nano is designed to make generative AI available directly on supported Android devices. Nano Lab explores what that means in practice rather than relying only on demonstrations or marketing descriptions.

The project evaluates:

- What Gemini Nano does well
- Where it fails, omits information, or hallucinates
- How consistently it follows instructions
- How generation settings affect output
- How repeatable its responses are
- How quickly each capability runs
- How availability and model downloads behave
- How Flutter communicates with the native Android APIs
- Whether inference continues working without an active internet connection
- How results differ across supported Pixel generations

Only fictional or disposable test content is used.

## Headline findings from the Pixel 10 Pro

- Deterministic date sorting preserved every fact across three identical runs.
- Structured extraction was factually reliable, but the model ignored an instruction to return undecorated JSON.
- Dedicated Summarization was approximately 2.7 times faster than freeform prompting but consistently omitted the article's central results.
- Rewriting preserved the supplied facts but added an unrequested sign-off and name placeholder.
- Proofreading corrected every planted error, preserved all facts, added nothing, and averaged approximately one second.
- Image Description produced identical wording across repeated runs but omitted a prominent tree and confidently misidentified an empty charging stand as a smartphone.
- Advanced Speech Recognition was impressively capable but made occasional meaningful substitutions.
- All six tested capabilities continued working after Nano Lab was restarted in airplane mode with Wi-Fi disabled.
- The release APK contained neither `INTERNET` nor `ACCESS_NETWORK_STATE`.

The most important general lesson was:

> Repeatability is not the same as correctness or completeness.

## Tested APIs

Nano Lab currently integrates:

```kotlin
implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
implementation("com.google.mlkit:genai-summarization:1.0.0-beta1")
implementation("com.google.mlkit:genai-rewriting:1.0.0-beta1")
implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
implementation("com.google.mlkit:genai-image-description:1.0.0-beta1")
implementation("com.google.mlkit:genai-speech-recognition:1.0.0-alpha1")
```

The application uses Google ML Kit GenAI APIs backed by Gemini Nano and Android's AICore service. The Flutter interface communicates with the native Kotlin implementation through platform channels.

## Privacy and network design

Nano Lab intentionally has:

- No cloud Gemini API
- No Firebase
- No analytics, advertising, or tracking
- No account system
- No database or persistent test history
- No audio recording storage
- No app-generated network requests
- No release `INTERNET` permission
- No release `ACCESS_NETWORK_STATE` permission

AICore may use the system's connection to obtain or manage required model assets. After those assets were installed, the tested capabilities continued working during a complete airplane-mode pass.

## Requirements

- Flutter development environment
- Android SDK
- A physical Android device supported by the relevant ML Kit GenAI APIs
- Android API level 26 or later
- Current AICore system service and required model assets
- Locked device bootloader where required by the APIs

The primary tested device is a stock Pixel 10 Pro running Android 17 / SDK 37. Feature availability may differ by device, model version, locale, operating-system version, and AICore state.

## Running Nano Lab

Clone the repository, enter its directory, and run:

```text
flutter pub get
flutter analyze
flutter test
flutter run
```

Use a supported physical Android device. Nano Lab displays each feature's status as `AVAILABLE`, `DOWNLOADABLE`, `DOWNLOADING`, or `UNAVAILABLE`. If a required asset is downloadable, complete that download while connected before attempting offline inference.

Do not use real patient, client, workplace, or otherwise sensitive information when experimenting with the app.

## Evaluation approach

The test harness exposes exact inputs and relevant settings, then records outputs and timings. Fixed tests make it possible to repeat the same request without silently changing the content.

The evaluation focuses on:

- Accuracy
- Completeness
- Repeatability
- Instruction following
- Latency
- Availability and download behavior
- Offline operation
- Appropriate and inappropriate practical uses

This is a focused independent evaluation, not a formal benchmark. The number of runs is deliberately limited, and the results should not be generalized to every device, prompt, image, speaker, locale, or future model update.

## Practical conclusion

Gemini Nano is useful for narrow, local, reversible tasks where a person can review the result. Examples include draft proofreading, suggested rewrites, optional summaries, draft transcription, local text organization, and supplemental image descriptions.

It should not be the sole authority for safety-critical decisions, exact transcription, automatic database writes, or visual interpretation where an omission or misidentification could cause harm. Generated structured output should be validated before use.

## Development and AI-assistance disclosure

This project was designed, run, and evaluated by Jason McArdle on physical Android hardware.

AI tools were used as development aids for coding, technical research, troubleshooting, and documentation. The reported measurements and device behavior came from Nano Lab running on the physical test device, not from simulated or AI-generated test results.

## Official documentation

- [ML Kit GenAI APIs overview](https://developers.google.com/ml-kit/genai)
- [GenAI Prompt API](https://developers.google.com/ml-kit/genai/prompt/android)
- [GenAI Summarization API](https://developers.google.com/ml-kit/genai/summarization/android)
- [GenAI Rewriting API](https://developers.google.com/ml-kit/genai/rewriting/android)
- [GenAI Proofreading API](https://developers.google.com/ml-kit/genai/proofreading/android)
- [GenAI Image Description API](https://developers.google.com/ml-kit/genai/image-description/android)
- [GenAI Speech Recognition API](https://developers.google.com/ml-kit/genai/speech-recognition/android)

## License

Copyright 2026 Jason McArdle.

Nano Lab is licensed under the [Apache License 2.0](LICENSE).

## Disclaimer

Nano Lab is an independent project and is not affiliated with, sponsored by, or endorsed by Google. Google, Android, Gemini, Gemini Nano, ML Kit, AICore, and Pixel are trademarks of their respective owners.

