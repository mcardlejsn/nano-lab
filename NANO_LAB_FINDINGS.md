# Nano Lab: Gemini Nano On-Device Evaluation

**Pixel 10 Pro findings — August 16, 2026**  
**Author:** Jason McArdle  
**Project:** [Nano Lab](https://github.com/mcardlejsn/nano-lab)

## Executive summary

Nano Lab is an Android-only Flutter experiment built to answer one central question:

> What can Gemini Nano reliably do on-device, what are its important limitations, and which practical uses are appropriate or inappropriate?

On a stock Google Pixel 10 Pro, Gemini Nano was genuinely useful for several narrow, well-defined tasks. It performed especially well at deterministic date sorting, factual extraction, proofreading, professional rewriting, and on-device speech recognition. The dedicated Proofreading API was the strongest result in this evaluation: it corrected every deliberately introduced error, preserved all facts, added nothing, returned identical output across four runs, and averaged approximately one second.

The tests also exposed meaningful limitations. Structured text output included unwanted Markdown fences. Rewriting repeatedly added an unrequested sign-off and name placeholder. The dedicated Summarization API was fast and factually sound but consistently omitted the article's central results. Image Description produced perfectly repeatable wording while omitting a prominent tree in a synthetic scene and misidentifying an empty charging stand as a smartphone in a real photograph. Speech Recognition occasionally made meaningful substitutions.

The most important general lesson is:

> Repeatability is not the same as correctness or completeness.

Gemini Nano appears well suited to private, local, reversible assistance where a person can review the result. It should not be trusted as the sole decision-maker, as an unvalidated structured-data parser, or as an exact source for safety-critical, medical, legal, financial, or accessibility information.

After all required model assets were downloaded, every tested capability continued working after an offline restart with airplane mode enabled and Wi-Fi disabled. A fresh release APK also contained neither the Android `INTERNET` nor `ACCESS_NETWORK_STATE` permission.

## Status of this report

This report completes the Pixel 10 Pro portion of Nano Lab. A controlled Pixel 11 Pro XL comparison will be added after that device becomes available. The present findings are complete for the tested device but should not be interpreted as a cross-device benchmark.

## Test environment

| Item | Configuration |
| --- | --- |
| Device | Stock Google Pixel 10 Pro |
| Operating system | Android 17 |
| Android SDK reported by app | 37 |
| Bootloader | Locked |
| Application | Nano Lab, Android-only Flutter app |
| Application ID | `com.mycarejournals.nano_lab` |
| Minimum Android SDK | 26 |
| Native integration | Kotlin bridge through Flutter platform channels |
| Model platform | Google ML Kit GenAI APIs, Gemini Nano, and AICore |
| Data used | Fictional text and disposable fixed images |
| Cloud AI | None |
| Persistent test history | None |

### Tested dependencies

```kotlin
implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
implementation("com.google.mlkit:genai-summarization:1.0.0-beta1")
implementation("com.google.mlkit:genai-rewriting:1.0.0-beta1")
implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
implementation("com.google.mlkit:genai-image-description:1.0.0-beta1")
implementation("com.google.mlkit:genai-speech-recognition:1.0.0-alpha1")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
```

The Prompt, Summarization, Rewriting, Proofreading, and Image Description APIs were beta APIs during testing. Speech Recognition was alpha. These APIs may change and are not covered by a stability guarantee.

## Methodology

Nano Lab uses fixed, visible inputs so runs can be repeated without changing the test content. It records the exact input, relevant settings, output, processing time, completion status, and available finish information. Session history exists only in memory.

The evaluation intentionally remained focused. It was designed to identify useful behavior and important failure modes rather than exhaustively test every parameter combination. The number of runs varied by capability, with repeated runs used where repeatability was central to the question.

Evaluation criteria included:

- Factual accuracy
- Completeness
- Repeatability
- Instruction following
- Latency
- Availability and model-download behavior
- Offline operation
- Suitability for practical use

The exact fixed test inputs are displayed in the application and represented in the repository source.

## Capability matrix

| Capability | Observed strengths | Important limitations | Typical measured time | Appropriate uses | Inappropriate uses |
| --- | --- | --- | ---: | --- | --- |
| Freeform Prompt | Flexible; reliable deterministic sorting and extraction; system instructions supported | Can ignore formatting details; generated JSON required sanitizing | About 4–7 seconds in the formal text tests | Drafting, local transformation, extraction with validation | Blind parsing, autonomous decisions, safety-critical conclusions |
| Summarization | Fast, repeatable, factually sound | Consistently prioritized routine rules over central results | 1.91-second average | Quick generic summaries where omissions are acceptable | Decision support requiring reliable prioritization of key facts |
| Rewriting | Preserved supplied facts and produced professional wording | Added an unrequested closing and `[Your Name]` placeholder | 5.21-second average | User-reviewed message drafting | Automatic sending or exact-template generation without review |
| Proofreading | Corrected every planted error; preserved facts; added nothing | Tested on one short controlled sentence | 1.04-second average | Short, user-reviewed grammar and spelling correction | Assuming every possible correction will be perfect |
| Image Description | Concise and perfectly repeatable on fixed images | Omitted a prominent object and confidently misidentified another | About 3.8 seconds after warm-up | Supplemental descriptions, draft metadata, user-reviewed accessibility assistance | Sole source for safety, navigation, inventory, or exact visual interpretation |
| Advanced Speech Recognition | Preserved the complete meaning in most runs; strong normalization of dates, quantities, and time | Occasional meaningful substitutions; compound-name formatting varied | 17.86-second average session time | Draft transcription with confirmation | Exact or safety-critical transcription without user review |
| Offline operation | All six capabilities remained available and completed inference offline | Airplane mode is practical evidence, not formal network forensics | Comparable to connected runs in this single pass | Private on-device assistance after assets are installed | Assuming assets never require initial download or future management |

## Detailed findings

### 1. Availability, downloads, and model selection

Gemini Nano initially reported `DOWNLOADABLE`. After an explicit asset download and application restart, it reported `AVAILABLE`.

Observed model availability:

- Stable Prompt model: `AVAILABLE`
- Preview Prompt model: `UNAVAILABLE`

Feature-specific behavior varied:

- Summarization was immediately available and did not require a separate visible download.
- Image Description required a feature-download request. The completion callback reported `0.0 MiB`, likely because the adapter was already present or completed immediately.
- Advanced Speech Recognition downloaded approximately `97.3 MiB` of required assets.

These results demonstrate why applications must check feature status instead of assuming that device support means every adapter is already ready.

### 2. Freeform Prompt API

Nano Lab tested:

- Optional system instructions
- Streaming output for one candidate
- Multiple complete candidates
- Temperature
- Maximum output tokens
- Seed
- Top-K
- Candidate count
- Stable versus Preview model selection
- Request-token count and combined token limit
- Finish reasons

Observed configuration range:

```text
Temperature: 0.0–1.0
Maximum output tokens: 1–4096
Seed: 0–2147483647
Top-K: positive integer
Candidate count: 1–8
Combined input/output limit: 8192 tokens
```

Observed finish reasons included `STOP (0)` and `MAX_TOKENS (1)`.

#### Generation controls

- Temperature `0.0` produced stable wording.
- Temperature `1.0` produced more varied but coherent wording.
- A fixed seed of `123` at temperature `1.0` produced identical output twice.
- Seed `0` was used for varying runs.
- Changing Top-K affected wording as expected.
- Multiple candidates produced distinct responses.

These controls changed how Nano selected and expressed an answer; they did not give the model additional knowledge.

#### Deterministic date sorting

Across three identical runs at temperature `0.0`, Nano correctly sorted five fictional ISO-dated records, preserved every fact, omitted nothing, invented nothing, and returned identical output.

| Run | Time |
| --- | ---: |
| 1 | 4.27 seconds |
| 2 | 4.02 seconds |
| 3 | 4.04 seconds |

**Finding:**

> At temperature 0.0, Gemini Nano reliably sorted five unambiguous ISO-dated records while preserving their exact factual content across three identical runs.

#### Structured JSON extraction

Across three identical runs, Nano extracted every supplied fact, used the required ordered keys, represented a missing room with `null`, and invented nothing.

However, every response was wrapped in Markdown `json` fences despite an explicit instruction to return undecorated JSON.

**Finding:**

> Gemini Nano was reliable at deterministic extraction and factual preservation, but applications must validate and sanitize generated structured output rather than parsing it blindly.

### 3. Dedicated Summarization API

Configuration:

- English
- Article input
- One-bullet output
- Approximately 355 fictional words
- Non-streaming inference

The dedicated API returned identical output across three runs:

| Run | Time |
| --- | ---: |
| 1 | 2.16 seconds |
| 2 | 1.79 seconds |
| 3 | 1.77 seconds |
| **Average** | **1.91 seconds** |

Its response was concise and factually correct, but it focused on operating rules and omitted the article's central results: membership, loans, grant spending, donations, survey support, and the pending funding decision.

A Freeform Prompt comparison used the same article and requested exactly one concise bullet without unsupported information:

| Run | Time |
| --- | ---: |
| 1 | 5.13 seconds |
| 2 | 5.17 seconds |
| **Average** | **5.15 seconds** |

The freeform response was longer and more informative while remaining factually sound.

**Finding:**

> On this 355-word fictional article, the dedicated Summarization API was approximately 2.7 times faster, but freeform prompting produced a more informative and useful one-bullet summary. Both were factually sound and repeatable, while the dedicated API consistently prioritized routine operating details over the article's central results.

### 4. Dedicated Rewriting API

Configuration:

- English
- Professional style
- Fewer than 256 input tokens
- Highest-confidence suggestion displayed

Exact input:

```text
hey sam, the fictional Alder Cove tool library opens Tuesday at 4:00 PM, and the town council votes on permanent funding October 12, 2026. please send me the inventory list by Friday so I can check it.
```

The API returned three suggestions per run. The highest-confidence result was identical across three runs:

```text
Hi Sam,

The fictional Alder Cove Tool Library opens on Tuesday at 4:00 PM. The town council will vote on permanent funding on October 12, 2026.

Could you please send me the inventory list by Friday so I can review it?

Thanks,
[Your Name]
```

| Run | Time |
| --- | ---: |
| 1 | 5.38 seconds |
| 2 | 5.09 seconds |
| 3 | 5.17 seconds |
| **Average** | **5.21 seconds** |

The output preserved all supplied facts, followed the professional style, and corrected capitalization and sentence structure. It also added an unrequested generic closing and name placeholder.

**Finding:**

> The dedicated Rewriting API reliably preserved facts and produced a professional rewrite, but it consistently added an unrequested sign-off and name placeholder.

### 5. Dedicated Proofreading API

Configuration:

- English
- Keyboard input
- Fewer than 256 input tokens
- Highest-confidence suggestion displayed

Exact input:

```text
the fictional Northbridge office recieve 17 packages on Monday, but three was labeld incorrect and needs to be checked by Friday.
```

Highest-confidence output:

```text
The fictional Northbridge office received 17 packages on Monday, but three were labeled incorrectly and need to be checked by Friday.
```

| Run | Time |
| --- | ---: |
| 1 | 1.14 seconds |
| 2 | 1.01 seconds |
| 3 | 1.01 seconds |
| 4 | 1.00 seconds |
| **Average** | **Approximately 1.04 seconds** |

The API corrected spelling, capitalization, subject-verb agreement, and word form. It preserved every fact, added nothing, and produced identical output across all four runs.

**Finding:**

> The dedicated Proofreading API corrected every deliberately introduced error, preserved all factual content, introduced nothing, and returned identical output across four runs at approximately one second per run.

### 6. Dedicated Image Description API

#### Synthetic scene

The app generates a fixed `768×512` synthetic scene locally in Kotlin. The displayed PNG and inference bitmap come from the same native function.

The scene contains a red house, brown roof, blue door, two yellow windows, green grass, blue sky, yellow sun, two white cloud groups, and a prominent green tree with a brown trunk.

Four runs produced exactly the same description:

```text
A red house with a brown roof, a blue door, and two yellow windows sits on green grass under a blue sky with a yellow sun and two white clouds.
```

| Run | Time |
| --- | ---: |
| 1 | 4.71 seconds |
| 2 | 3.83 seconds |
| 3 | 3.79 seconds |
| 4 | 3.84 seconds |
| **Overall average** | **4.04 seconds** |
| **Warm-run average** | **3.82 seconds** |

The description correctly captured the central scene, colors, number of windows, and number of cloud groups. It did not hallucinate any detail. However, it omitted the prominent tree in every run.

**Finding:**

> Across four identical runs, the Image Description API returned exactly the same accurate description. Processing stabilized near 3.8 seconds after a slower initial run. However, every response omitted the prominent tree, demonstrating that a concise description can remain factually correct while still excluding visually significant information.

#### Real tabletop photograph

The bundled `1157×1536` photograph contains:

- Coca-Cola bottle
- Empty magnetic phone-charging stand
- Black computer mouse
- Pen
- Black lamp
- Gray tabletop

All four runs returned exactly:

```text
A Coca-Cola bottle, a smartphone on a stand, a pen, and a small black object are arranged on a gray tabletop next to a lamp.
```

| Run | Time |
| --- | ---: |
| 1 | 4.06 seconds |
| 2 | 3.68 seconds |
| 3 | 3.61 seconds |
| 4 | 3.64 seconds |
| **Average** | **Approximately 3.75 seconds** |

The API correctly recognized the bottle, pen, lamp, tabletop, and overall scene. It misidentified the empty charging stand as a smartphone and described the clearly visible mouse only as “a small black object.”

**Finding:**

> Strong repeatability did not guarantee complete or correct object identification. The same confident visual error was reproduced in every run.

### 7. Advanced GenAI Speech Recognition API

Configuration:

- Advanced mode using the GenAI model
- Locale: `en-US`
- Live microphone input
- Partial and committed transcription events
- No audio recording storage

Fixed phrase:

```text
On Monday, August seventeenth, twenty twenty-six, the fictional Northbridge office received seventeen packages. Three were labeled incorrectly and must be checked by Friday at four fifteen P.M.
```

#### Application aggregation correction

The first apparent recognition failures were invalid because the native bridge replaced earlier committed `FinalTextResponse` segments when a later segment arrived. Google ML Kit emits multiple committed final segments. The bridge was corrected to accumulate them and normalize each segment boundary to exactly one space.

Pre-correction transcripts were excluded from the accuracy evaluation.

#### Four valid measured runs

| Run | Session time | Meaningful difference |
| --- | ---: | --- |
| 1 | 19.38 seconds | “Three” became “they”; “labeled” became “labor” |
| 2 | 18.28 seconds | “received” became “receives”; “incorrectly” became “in correctly” |
| 3 | 17.19 seconds | Essentially perfect with normal formatting differences |
| 4 | 16.60 seconds | “fictional” became “fixed” |
| **Average** | **Approximately 17.86 seconds** | — |

These values are complete microphone-session times, including speaking and manual interaction. They are not pure model-inference latency.

`Northbridge` was rendered as `North Bridge` in three of four runs. This was treated mainly as compound-name formatting because it preserved the intended meaning. Dates, quantities, and times were generally normalized appropriately, including `August 17th, 2026`, `17 packages`, and `4:15 p.m.`

Across roughly 108 reference words, the four runs contained approximately four meaningful substitutions. This corresponds to an informal content-accuracy estimate of about 96%; it is not a formal word-error-rate calculation.

One additional post-correction verification run took 19.88 seconds and was essentially perfect:

```text
on Monday, August 17th, 2026. The fictional North Bridge office received 17 packages. Three were labeled incorrectly and must be checked by Friday at 4:15 p.m.
```

**Finding:**

> Advanced on-device speech recognition was impressively capable and usually preserved the complete meaning of the fixed two-sentence phrase. However, it produced occasional meaningful substitutions, so it should not be treated as exact or safety-critical transcription without user review and confirmation.

Basic mode was intentionally not tested because it uses a traditional on-device recognizer rather than the Gemini Nano model and would not materially answer Nano Lab's central question.

## Offline-operation verification

After all required assets were available, the following procedure was performed on the Pixel 10 Pro:

1. Confirmed the tested features were `AVAILABLE` while connected.
2. Enabled airplane mode.
3. Explicitly disabled Wi-Fi.
4. Fully stopped Nano Lab.
5. Reopened Nano Lab while still offline.
6. Ran one representative test through Freeform Prompt, Summarization, Rewriting, Proofreading, Image Description, and Advanced Speech Recognition.
7. Kept airplane mode enabled and Wi-Fi disabled throughout the complete pass.

All six capabilities remained available and completed inference.

Representative recorded results included:

| Capability | Offline result |
| --- | --- |
| Freeform Prompt | Completed |
| Summarization | Completed in 1.89 seconds |
| Rewriting | `AVAILABLE`; completed in 5.49 seconds |
| Proofreading | `AVAILABLE`; completed in 1.13 seconds |
| Image Description | `AVAILABLE`; completed in 3.85 seconds |
| Advanced Speech Recognition | `AVAILABLE`; completed in 21.76 seconds with an essentially perfect transcription |

The offline Speech Recognition output preserved the full content, with `Northbridge` rendered as `North Bridge`:

```text
on Monday, August 17th, 2026, the fictional North Bridge office received 17 packages. Three were labeled incorrectly and must be checked by Friday at 4:15 p.m.
```

**Offline finding:**

> On the Pixel 10 Pro, after all required assets were downloaded, Nano Lab's six tested ML Kit GenAI capabilities remained available and completed inference after an offline restart with airplane mode enabled and Wi-Fi disabled.

Airplane mode provides strong practical evidence of offline operation but is not formal network-forensics proof.

## Release APK permission verification

After the offline test, a fresh release APK was built and inspected using Android's AAPT2 permission-dump command.

Quality checks:

```text
flutter analyze: No issues found
flutter test: All tests passed
flutter build apk --release: Successful
Release APK size: 48.2 MB
```

Permissions packaged in the release APK:

```text
android.permission.RECORD_AUDIO
com.google.android.apps.aicore.service.BIND_SERVICE
com.mycarejournals.nano_lab.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

The release APK contained neither:

```text
android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
```

The microphone permission supports Speech Recognition. `BIND_SERVICE` supports communication with the on-device AICore service. The application-specific dynamic-receiver permission supports internal Android component communication.

**Combined offline finding:**

> The successful airplane-mode pass and absence of both network permissions provide strong practical and package-level evidence that Nano Lab itself performs the tested inference without an active internet connection. AICore may independently use connectivity to obtain or manage model assets when connectivity is available.

## What Gemini Nano was genuinely good at

Within the tested scope, Gemini Nano was strongest at:

- Narrow tasks with explicit inputs and objective outputs
- Deterministic sorting and fact-preserving extraction
- Short proofreading tasks
- Professional rewriting when the result remained user-reviewed
- Fast dedicated inference for proofreading and summarization
- Repeatable responses under controlled settings
- Useful draft-quality speech transcription
- Maintaining functionality after assets were installed and the phone was taken offline

## Where it failed or required caution

Observed limitations included:

- Ignoring an explicit instruction to return undecorated JSON
- Omitting central information from a factually correct summary
- Adding an unrequested closing and placeholder to rewritten text
- Omitting a prominent object from an image description
- Confidently identifying an empty stand as a smartphone
- Describing a visible mouse only generically
- Making occasional meaningful speech substitutions
- Producing identical incorrect or incomplete output across repeated runs

No serious factual hallucination appeared in the controlled text-extraction, sorting, summarization, rewriting, or proofreading tests. The clearest confident false assertion occurred in Image Description when the empty charging stand was described as a smartphone.

## Practical recommendations

### Appropriate uses

Gemini Nano appears appropriate for tasks that are:

- Local and privacy-sensitive
- Narrowly scoped
- Reversible
- Easy for a user to review
- Tolerant of occasional omissions or wording changes
- Protected by deterministic validation where structured data is involved

Examples include draft proofreading, suggested rewrites, optional summaries, draft transcriptions, local text organization, and supplemental image descriptions.

### Inappropriate uses

Gemini Nano should not be the sole authority for:

- Medical, legal, financial, or safety-critical decisions
- Exact transcription without confirmation
- Automatic extraction into a database without schema validation and review
- Accessibility descriptions where omitted or misidentified objects could create danger
- Autonomous actions based on generated content
- Any workflow that assumes repeatable output must therefore be correct

For structured tasks, ordinary deterministic code should be used whenever the task can be solved reliably without a language model.

## Limitations of this evaluation

- Most testing was performed on one Pixel 10 Pro.
- The future Pixel 11 Pro XL comparison is not yet included.
- The test set was deliberately small and controlled.
- Results should not be generalized to every prompt, image, accent, environment, device, locale, or model update.
- Speech accuracy was estimated informally and was not calculated using a formal word-error-rate tool.
- Speech timing included speaking and manual interaction.
- Airplane mode was used instead of packet capture or operating-system network instrumentation.
- The tested APIs were beta or alpha and may change.
- The stable Prompt model was tested; the Preview model was unavailable.
- No attempt was made to test every generation-setting combination.
- No production medical or caregiver data was used.

## Planned Pixel 11 Pro XL addendum

When the Pixel 11 Pro XL becomes available, Nano Lab will repeat a small set of the same controlled tests. The comparison will focus on:

- Feature availability
- Required asset downloads
- Output equivalence or meaningful differences
- Processing time
- Speech Recognition behavior
- Offline operation

The comparison will use the same inputs and settings rather than introducing new test content. This report will then be updated with a concise cross-device table and conclusions.

## Development and AI-assistance disclosure

I am an independent Flutter developer evaluating whether Gemini Nano's on-device capabilities are practical and reliable. I designed the project, selected the evaluation questions, ran the tests on real hardware, recorded the outputs, identified practical successes and failures, and accepted responsibility for the conclusions.

AI assistance was used for implementation support, API research, troubleshooting, interpretation of technical concepts, and drafting documentation. The reported measurements and device behavior came from Nano Lab running on my physical Pixel 10 Pro, not from simulated or AI-generated test results.

## Conclusion

Gemini Nano is not merely a novelty. On supported hardware, it can provide useful private, offline assistance with respectable speed and strong repeatability. Its best results came from narrow tasks where correctness was easy to inspect, particularly proofreading and deterministic text transformation.

Its limitations are equally important. It can produce output that is fluent, confident, repeatable, and still incomplete or wrong. The Image Description results demonstrated this most clearly. The model therefore belongs inside carefully bounded, user-reviewed workflows—not in positions where its output is silently trusted.

The Pixel 10 Pro results support this overall conclusion:

> Gemini Nano is practically useful for local, reviewable assistance, but its output must be validated according to the risk of the task. Strong repeatability should increase confidence only when correctness and completeness have also been independently verified.

## Official API references

- [ML Kit GenAI APIs overview](https://developers.google.com/ml-kit/genai)
- [GenAI Prompt API](https://developers.google.com/ml-kit/genai/prompt/android)
- [GenAI Summarization API](https://developers.google.com/ml-kit/genai/summarization/android)
- [GenAI Rewriting API](https://developers.google.com/ml-kit/genai/rewriting/android)
- [GenAI Proofreading API](https://developers.google.com/ml-kit/genai/proofreading/android)
- [GenAI Image Description API](https://developers.google.com/ml-kit/genai/image-description/android)
- [GenAI Speech Recognition API](https://developers.google.com/ml-kit/genai/speech-recognition/android)
- [Android AAPT2 documentation](https://developer.android.com/tools/aapt2)

