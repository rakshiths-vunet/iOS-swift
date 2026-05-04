const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageNumber, PageBreak, Header, Footer, TabStopType, TabStopPosition
} = require('docx');
const fs = require('fs');

// ── Colors ──────────────────────────────────────────────────────────────────
const C = {
  teal:       "1D9E75",
  tealLight:  "E1F5EE",
  tealDark:   "0F6E56",
  blue:       "185FA5",
  blueLight:  "E6F1FB",
  purple:     "534AB7",
  purpleLight:"EEEDFE",
  amber:      "BA7517",
  amberLight: "FAEEDA",
  red:        "A32D2D",
  redLight:   "FCEBEB",
  gray:       "5F5E5A",
  grayLight:  "F1EFE8",
  black:      "1A1A1A",
  white:      "FFFFFF",
  rule:       "D3D1C7",
};

const border = (color = C.rule, size = 4) => ({ style: BorderStyle.SINGLE, size, color });
const noBorder = () => ({ style: BorderStyle.NIL, size: 0, color: C.white });
const allBorders = (color, size) => ({ top: border(color, size), bottom: border(color, size), left: border(color, size), right: border(color, size) });
const noBorders = () => ({ top: noBorder(), bottom: noBorder(), left: noBorder(), right: noBorder() });

// ── Typography helpers ───────────────────────────────────────────────────────
const mono = (text, color = C.blue, size = 18) => new TextRun({ text, font: "Courier New", size, color });
const bold = (text, color = C.black, size = 22) => new TextRun({ text, bold: true, font: "Arial", size, color });
const reg  = (text, color = C.black, size = 22) => new TextRun({ text, font: "Arial", size, color });
const muted= (text, size = 20) => new TextRun({ text, font: "Arial", size, color: C.gray });
const tag  = (text, bg, fg) => new TextRun({ text: ` ${text} `, font: "Courier New", size: 16, color: fg, shading: { fill: bg, type: ShadingType.CLEAR } });

const p = (children, opts = {}) => new Paragraph({ children: Array.isArray(children) ? children : [children], ...opts });
const h1 = (text) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ text, font: "Arial", size: 36, bold: true, color: C.black })] });
const h2 = (text) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun({ text, font: "Arial", size: 28, bold: true, color: C.tealDark })] });
const h3 = (text) => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun({ text, font: "Arial", size: 24, bold: true, color: C.black })] });
const rule = () => new Paragraph({ border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.rule, space: 1 } }, children: [new TextRun("")], spacing: { before: 120, after: 120 } });
const spacer = (before = 80, after = 80) => new Paragraph({ children: [new TextRun("")], spacing: { before, after } });

const bullet = (children, level = 0) => new Paragraph({
  numbering: { reference: "bullets", level },
  children: Array.isArray(children) ? children : [new TextRun({ text: children, font: "Arial", size: 22, color: C.black })],
  spacing: { before: 40, after: 40 }
});

const numbered = (children, level = 0, ref = "numbers") => new Paragraph({
  numbering: { reference: ref, level },
  children: Array.isArray(children) ? children : [new TextRun({ text: children, font: "Arial", size: 22, color: C.black })],
  spacing: { before: 60, after: 60 }
});

// ── Code block (single-line or array of lines) ───────────────────────────────
const codeBlock = (lines) => {
  const arr = Array.isArray(lines) ? lines : [lines];
  return arr.map((line, i) => new Paragraph({
    children: [new TextRun({ text: line, font: "Courier New", size: 18, color: C.tealDark })],
    shading: { fill: C.grayLight, type: ShadingType.CLEAR },
    border: i === 0
      ? { top: border(C.rule, 4), left: border(C.teal, 12), right: border(C.rule, 4) }
      : { left: border(C.teal, 12), right: border(C.rule, 4) },
    indent: { left: 240, right: 240 },
    spacing: { before: i === 0 ? 80 : 0, after: i === arr.length - 1 ? 80 : 0, line: 300, lineRule: "auto" },
  }));
};

// ── Colored banner paragraph ──────────────────────────────────────────────────
const banner = (label, text, bg, fg) => new Paragraph({
  children: [
    new TextRun({ text: `  ${label}  `, font: "Courier New", size: 18, bold: true, color: fg, shading: { fill: bg, type: ShadingType.CLEAR } }),
    new TextRun({ text: "  " }),
    new TextRun({ text, font: "Arial", size: 20, color: C.black }),
  ],
  shading: { fill: C.grayLight, type: ShadingType.CLEAR },
  indent: { left: 200, right: 200 },
  spacing: { before: 60, after: 60 },
  border: { left: border(fg, 16) },
});

// ── Two-column table row (label | value) ──────────────────────────────────────
const metaRow = (label, value, shade = false) => new TableRow({
  children: [
    new TableCell({
      width: { size: 2500, type: WidthType.DXA },
      borders: allBorders(C.rule, 4),
      shading: { fill: shade ? C.grayLight : C.white, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [p([bold(label, C.gray, 20)])],
    }),
    new TableCell({
      width: { size: 6860, type: WidthType.DXA },
      borders: allBorders(C.rule, 4),
      shading: { fill: C.white, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [p([reg(value, C.black, 20)])],
    }),
  ]
});

const metaTable = (rows) => new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [2500, 6860],
  rows: rows.map((r, i) => metaRow(r[0], r[1], i % 2 === 0)),
});

// ── Scenario card row ─────────────────────────────────────────────────────────
const scenarioRow = (id, name, badge, badgeBg, badgeFg, desc, steps) => new TableRow({
  children: [
    new TableCell({
      width: { size: 700, type: WidthType.DXA },
      borders: allBorders(C.rule, 4),
      shading: { fill: C.tealLight, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 80, right: 80 },
      verticalAlign: "center",
      children: [p([new TextRun({ text: id, font: "Courier New", size: 18, bold: true, color: C.tealDark })], { alignment: AlignmentType.CENTER })],
    }),
    new TableCell({
      width: { size: 4260, type: WidthType.DXA },
      borders: allBorders(C.rule, 4),
      shading: { fill: C.white, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [
        p([bold(name, C.black, 20)]),
        p([muted(desc, 18)], { spacing: { before: 40 } }),
        p([muted("Steps: ", 18), new TextRun({ text: steps, font: "Courier New", size: 17, color: C.gray })], { spacing: { before: 40 } }),
      ],
    }),
    new TableCell({
      width: { size: 1300, type: WidthType.DXA },
      borders: allBorders(C.rule, 4),
      shading: { fill: badgeBg, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 80, right: 80 },
      verticalAlign: "center",
      children: [p([new TextRun({ text: badge, font: "Courier New", size: 17, bold: true, color: badgeFg })], { alignment: AlignmentType.CENTER })],
    }),
  ]
});

const scenarioHeader = () => new TableRow({
  children: ["ID", "Scenario", "Type"].map((t, i) => new TableCell({
    width: { size: [700, 4260, 1300][i], type: WidthType.DXA },
    borders: allBorders(C.teal, 6),
    shading: { fill: C.tealDark, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [p([new TextRun({ text: t, font: "Arial", size: 20, bold: true, color: C.white })])],
  }))
});

// ── File tree table ───────────────────────────────────────────────────────────
const treeRow = (indent, name, desc, color = C.black, isFolder = false) => new TableRow({
  children: [
    new TableCell({
      width: { size: 4200, type: WidthType.DXA },
      borders: { top: noBorder(), bottom: noBorder(), left: noBorder(), right: border(C.rule, 4) },
      margins: { top: 40, bottom: 40, left: 120 + indent * 160, right: 120 },
      children: [p([new TextRun({ text: name, font: "Courier New", size: isFolder ? 19 : 18, bold: isFolder, color })])],
    }),
    new TableCell({
      width: { size: 5160, type: WidthType.DXA },
      borders: noBorders(),
      margins: { top: 40, bottom: 40, left: 120, right: 120 },
      children: [p([muted(desc, 18)])],
    }),
  ]
});

const fileTree = new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [4200, 5160],
  rows: [
    treeRow(0, "RUMSimulator/", "── Project root", C.black, true),
    treeRow(1, "AppDelegate.swift", "UIApplication entry · SDK bootstrap hook location", C.blue),
    treeRow(1, "SceneDelegate.swift", "Scene lifecycle · foreground / background hooks", C.blue),
    treeRow(1, "Info.plist", "NSAppTransportSecurity exception for httpbin.org", C.amber),
    treeRow(0, "Engine/", "── Scenario orchestration layer", C.tealDark, true),
    treeRow(1, "ScenarioEngine.swift", "Step executor · timing · speed multiplier · start/stop", C.teal),
    treeRow(1, "Scenario.swift", "Scenario + ScenarioStep model structs (Codable)", C.teal),
    treeRow(1, "ScenarioLibrary.swift", "Factory that returns all 6 predefined Scenario instances", C.teal),
    treeRow(1, "EngineState.swift", "@Observable: currentScenario, stepIndex, eventRate", C.teal),
    treeRow(1, "LoadGenerator.swift", "Burst / sustained / mixed load modes", C.teal),
    treeRow(0, "Scenarios/", "── Concrete step definitions (one file per scenario)", C.tealDark, true),
    treeRow(1, "S1_BasicNavigation.swift", "Push A→B→C→D, pop, present modal, dismiss", C.teal),
    treeRow(1, "S2_RapidInteraction.swift", "Tap burst loop, scroll, long press, swipe", C.teal),
    treeRow(1, "S3_NetworkStress.swift", "Parallel URLSession: success/slow/error/DNS-fail", C.teal),
    treeRow(1, "S4_SessionRestart.swift", "Actions → background → wait → resume → continue", C.teal),
    treeRow(1, "S5_ColdStart.swift", "Immediate nav + network calls on first launch", C.teal),
    treeRow(1, "S6_MixedLoad.swift", "Continuous nav + interaction + network loop", C.teal),
    treeRow(0, "Screens/", "── All UI screens (UIKit + SwiftUI)", C.blue, true),
    treeRow(1, "ControlPanel/ControlPanelViewController.swift", "Home screen: mode toggle, scenario picker, live status", C.blue),
    treeRow(1, "ControlPanel/ControlPanelViewModel.swift", "@Observable bridging EngineState → UI", C.blue),
    treeRow(1, "Navigation/UIKitNavPlaygroundVC.swift", "UINavigationController deep-stack playground", C.blue),
    treeRow(1, "Navigation/SwiftUINavPlayground.swift", "NavigationStack with programmatic navigation", C.blue),
    treeRow(1, "Navigation/NavLevelViewController.swift", "Reusable UIKit screen for stack levels A/B/C/D", C.blue),
    treeRow(1, "Navigation/ModalViewController.swift", "Modal presentation target", C.blue),
    treeRow(1, "Interaction/InteractionPlaygroundVC.swift", "Tap burst, scroll velocity, gestures UI", C.blue),
    treeRow(1, "Interaction/GestureSimulator.swift", "Programmatic gesture dispatch (used by engine)", C.blue),
    treeRow(1, "Network/NetworkPlaygroundVC.swift", "Sequential / parallel / retry call UI", C.blue),
    treeRow(1, "Lifecycle/LifecyclePlaygroundVC.swift", "Background/foreground trigger UI, inactivity timer", C.blue),
    treeRow(1, "CrashError/CrashPlaygroundVC.swift", "fatalError (guarded), freeze sim, non-fatal errors", C.blue),
    treeRow(1, "DebugPanel/DebugPanelViewController.swift", "Hidden panel (shake): speed, failure rate, reset", C.blue),
    treeRow(1, "DebugPanel/DebugPanelViewModel.swift", "Speed multiplier, failure rate, delay override state", C.blue),
    treeRow(0, "Network/", "── Pure networking layer (no UIKit)", C.amber, true),
    treeRow(1, "NetworkSimulator.swift", "URLSession wrapper · applies debug-panel overrides", C.amber),
    treeRow(1, "HTTPBinEndpoints.swift", "Endpoint enum: .get .delay(n) .status(n) .invalidDomain", C.amber),
    treeRow(1, "NetworkResult.swift", "Result type: success / clientError / serverError / timeout", C.amber),
    treeRow(0, "Logging/", "── Local event capture and export", C.purple, true),
    treeRow(1, "EventLogger.swift", "In-memory ring buffer (500 events) + async file write", C.purple),
    treeRow(1, "LogEvent.swift", "Codable struct: timestamp, type, scenario, step, metadata", C.purple),
    treeRow(1, "LogViewerViewController.swift", "Live list, type filter, UIActivityViewController export", C.purple),
    treeRow(1, "LogFileManager.swift", "Per-scenario file rotation · JSON → /Documents/rum_log_*.json", C.purple),
    treeRow(0, "Coordinator/", "── Dependency wiring and routing", C.gray, true),
    treeRow(1, "AppCoordinator.swift", "Root: wires engine, logger, nav, debug panel", C.gray),
    treeRow(1, "PlaygroundCoordinator.swift", "Routes between all playgrounds (UIKit + SwiftUI)", C.gray),
    treeRow(0, "Lifecycle/", "── Infrastructure (not a screen)", C.gray, true),
    treeRow(1, "LifecycleObserver.swift", "SceneDelegate → EventLogger bridge for phase transitions", C.gray),
    treeRow(0, "Resources/", "── Static assets", C.gray, true),
    treeRow(1, "Assets.xcassets", "App icon, accent colours — no images needed", C.gray),
    treeRow(1, "LaunchScreen.storyboard", "Minimal splash — cold-start timing reference point", C.gray),
  ]
});

// ── Copilot instruction block ────────────────────────────────────────────────
const copilotNote = () => new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [9360],
  rows: [new TableRow({ children: [new TableCell({
    width: { size: 9360, type: WidthType.DXA },
    borders: allBorders(C.purple, 6),
    shading: { fill: C.purpleLight, type: ShadingType.CLEAR },
    margins: { top: 120, bottom: 120, left: 200, right: 200 },
    children: [
      p([bold("COPILOT INSTRUCTION BLOCK", C.purple, 22)]),
      spacer(60, 40),
      p([reg("You are generating a complete iOS application in Swift. Follow every requirement in this document exactly. Key rules:", C.black, 20)]),
      spacer(40, 40),
      bullet([bold("No manual instrumentation. ", C.red, 20), reg("Zero SDK API calls. No custom spans. All signals must come from UIKit, SwiftUI, URLSession, or OS lifecycle callbacks.", C.black, 20)]),
      bullet([bold("URLSession only ", C.red, 20), reg("for all network traffic. Never import Alamofire, AFNetworking, or any third-party network library.", C.black, 20)]),
      bullet([bold("Swift 5+ idioms. ", C.black, 20), reg("Use async/await for async work. Use @Observable (iOS 17+) for state. Fall back to @ObservableObject for iOS 15 targets.", C.black, 20)]),
      bullet([bold("UIKit + SwiftUI hybrid. ", C.black, 20), reg("Navigation playground has both a UIKit flow and a SwiftUI flow. All other screens may use either framework.", C.black, 20)]),
      bullet([bold("No third-party dependencies ", C.black, 20), reg("of any kind. GCD and async/await only.", C.black, 20)]),
      bullet([bold("Generate all files listed in Section 5. ", C.black, 20), reg("Every file must compile. Stub bodies are acceptable for UI-only screens, but all engine, network, and logging files must be fully functional.", C.black, 20)]),
      bullet([bold("Crash playground ", C.red, 20), reg("must show a UIAlertController confirmation before calling fatalError.", C.black, 20)]),
    ],
  })]})],
});

// ── Document ──────────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 560, hanging: 280 } } }
        }, {
          level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1000, hanging: 280 } } }
        }]
      },
      {
        reference: "numbers",
        levels: [{
          level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 560, hanging: 280 } } }
        }]
      },
      {
        reference: "constraints",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "✗", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 560, hanging: 280 } } }
        }]
      },
    ]
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22, color: C.black } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 40, bold: true, font: "Arial", color: C.black },
        paragraph: { spacing: { before: 360, after: 160 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: C.tealDark },
        paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1, border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.tealLight } } } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: C.black },
        paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 } },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          children: [
            new TextRun({ text: "RUM Scenario Simulator — Technical PRD & Copilot Prompt", font: "Arial", size: 18, color: C.gray }),
            new TextRun({ text: "\t", font: "Arial", size: 18 }),
            new TextRun({ text: "CONFIDENTIAL · Internal", font: "Arial", size: 18, color: C.gray }),
          ],
          tabStops: [{ type: TabStopType.RIGHT, position: TabStopPosition.MAX }],
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.rule } },
          spacing: { after: 80 },
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          children: [
            new TextRun({ text: "v1.0 · iOS · Swift 5+ · UIKit + SwiftUI", font: "Arial", size: 18, color: C.gray }),
            new TextRun({ text: "\t", font: "Arial", size: 18 }),
            new TextRun({ children: [new PageNumber()], font: "Arial", size: 18, color: C.gray }),
          ],
          tabStops: [{ type: TabStopType.RIGHT, position: TabStopPosition.MAX }],
          border: { top: { style: BorderStyle.SINGLE, size: 4, color: C.rule } },
          spacing: { before: 80 },
        })]
      })
    },
    children: [

      // ── COVER ──────────────────────────────────────────────────────────────
      new Paragraph({
        children: [new TextRun({ text: "RUM SCENARIO SIMULATOR", font: "Arial", size: 56, bold: true, color: C.black })],
        spacing: { before: 400, after: 80 }
      }),
      new Paragraph({
        children: [new TextRun({ text: "Technical PRD  ·  Copilot Prompt  ·  iOS Swift", font: "Arial", size: 28, color: C.teal })],
        spacing: { after: 160 }
      }),
      rule(),
      spacer(60, 0),

      metaTable([
        ["Platform",      "iOS 16+ (deployment target iOS 16.0)"],
        ["Language",      "Swift 5.9+"],
        ["UI Framework",  "UIKit + SwiftUI (hybrid — both required)"],
        ["Networking",    "URLSession only — no third-party libraries"],
        ["Architecture",  "Coordinator pattern + @Observable state"],
        ["Async model",   "async/await + GCD (DispatchQueue)"],
        ["Type",          "Internal developer tool — synthetic RUM signal generator"],
        ["SDK policy",    "Zero manual instrumentation — auto-capture only"],
      ]),

      spacer(200),
      new Paragraph({ children: [new PageBreak()], spacing: { before: 0, after: 0 } }),

      // ── COPILOT BLOCK ──────────────────────────────────────────────────────
      h1("0.  Copilot Prompt — Read First"),
      copilotNote(),
      spacer(120),

      // ── S1: PURPOSE ────────────────────────────────────────────────────────
      h1("1.  Purpose & Background"),
      p([reg("This app is a synthetic iOS application built exclusively to validate the auto-instrumentation capabilities of a Real User Monitoring (RUM) SDK. It generates controlled, repeatable telemetry signals — page navigations, user interactions, network requests, app lifecycle events — without writing a single manual instrumentation call.")]),
      spacer(60),
      p([reg("The core premise: if the SDK's auto-capture is wired correctly, it must observe everything this app does simply by being linked into the binary. No wrapper APIs. No custom spans. No event tracking calls.")]),
      spacer(60),
      banner("WHY", "Every signal in this app must be a side-effect of normal UIKit / SwiftUI / URLSession behaviour, not an explicit SDK call.", C.tealLight, C.tealDark),
      spacer(80),

      // ── S2: GOALS ─────────────────────────────────────────────────────────
      h1("2.  Goals & Non-Goals"),
      h2("2.1  Goals"),
      bullet("Validate auto-instrumented telemetry across all SDK signal surfaces"),
      bullet("Simulate realistic synthetic user journeys in a controlled, repeatable way"),
      bullet("Run deterministic scripted scenarios with configurable speed and intensity"),
      bullet("Stress-test the SDK with high event volumes (burst and sustained modes)"),
      bullet("Support both manual developer exploration and automated scripted runs"),
      bullet("Provide local logs to cross-reference what the SDK should be capturing"),
      spacer(80),
      h2("2.2  Non-Goals"),
      bullet("No business logic or real product flows"),
      bullet("No manual span or event creation via any SDK API"),
      bullet("No backend ownership — the app is a signal emitter only"),
      bullet("No third-party dependencies of any kind (no CocoaPods, no SPM external packages)"),
      bullet("No analytics dashboards or reporting inside the app"),
      spacer(120),

      // ── S3: ARCHITECTURE ──────────────────────────────────────────────────
      h1("3.  Architecture"),
      h2("3.1  Layer Overview"),
      p([reg("The app has four horizontal layers. Dependencies flow downward only — the engine never imports UIKit, and screens never directly call the logger.")]),
      spacer(60),

      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2000, 7360],
        rows: [
          new TableRow({ children: [
            new TableCell({ width:{size:2000,type:WidthType.DXA}, borders: allBorders(C.teal,6), shading:{fill:C.tealDark,type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[p([new TextRun({text:"Layer",font:"Arial",size:20,bold:true,color:C.white})])] }),
            new TableCell({ width:{size:7360,type:WidthType.DXA}, borders: allBorders(C.teal,6), shading:{fill:C.tealDark,type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[p([new TextRun({text:"Responsibility",font:"Arial",size:20,bold:true,color:C.white})])] }),
          ]}),
          ...[
            ["App Entry", "AppDelegate + SceneDelegate. SDK link point. LifecycleObserver wired here."],
            ["Engine", "ScenarioEngine executes scripted steps. ScenarioLibrary holds all 6 scenarios. LoadGenerator drives burst/sustained modes."],
            ["Screens", "All UIKit and SwiftUI screens. ControlPanel is the root. Six playground modules. DebugPanel is hidden."],
            ["Support", "EventLogger (ring buffer + file), LogFileManager (rotation), AppCoordinator (DI wiring), PlaygroundCoordinator (routing)."],
          ].map(([l,v], i) => new TableRow({ children: [
            new TableCell({ width:{size:2000,type:WidthType.DXA}, borders:allBorders(C.rule,4), shading:{fill: i%2===0?C.grayLight:C.white, type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[p([bold(l,C.black,20)])] }),
            new TableCell({ width:{size:7360,type:WidthType.DXA}, borders:allBorders(C.rule,4), shading:{fill:C.white,type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[p([reg(v,C.black,20)])] }),
          ]}))
        ]
      }),

      spacer(120),
      h2("3.2  Key Architecture Decisions"),
      bullet([bold("AppCoordinator is the only class that touches all layers. ", C.black, 22), reg("It holds references to ScenarioEngine, EventLogger, PlaygroundCoordinator and passes them via initialiser injection. No singletons.", C.black, 22)]),
      bullet([bold("Scenarios/ is separate from Engine/. ", C.black, 22), reg("ScenarioEngine is generic infrastructure. Concrete step arrays live in Scenarios/ so new scenarios can be added without touching the engine.", C.black, 22)]),
      bullet([bold("Network/ (root) is pure logic. ", C.black, 22), reg("Screens/Network/ is the playground UI. The engine imports from root Network/, not the screen.", C.black, 22)]),
      bullet([bold("LifecycleObserver is infrastructure, not a screen. ", C.black, 22), reg("It bridges SceneDelegate callbacks to the logger independently of any playground UI.", C.black, 22)]),
      spacer(120),

      // ── S4: CORE DATA MODELS ──────────────────────────────────────────────
      h1("4.  Core Data Models"),
      h2("4.1  ScenarioStep"),
      ...codeBlock([
        "struct ScenarioStep {",
        "    let label: String           // shown in ControlPanel live readout",
        "    let action: () -> Void      // main-thread-safe closure",
        "    let delay: TimeInterval     // seconds before next step fires",
        "}",
      ]),
      spacer(60),
      h2("4.2  Scenario"),
      ...codeBlock([
        "struct Scenario {",
        "    let id: String",
        "    let name: String",
        "    let steps: [ScenarioStep]",
        "    let loop: Bool              // restart automatically when complete",
        "}",
      ]),
      spacer(60),
      h2("4.3  LogEvent"),
      ...codeBlock([
        "struct LogEvent: Codable {",
        "    let timestamp: Date",
        "    let type: String            // \"navigation\" | \"tap\" | \"network\" | \"lifecycle\" | \"crash\"",
        "    let scenario: String?       // active scenario name, if any",
        "    let step: Int?              // step index within scenario",
        "    let metadata: [String: String]",
        "}",
      ]),
      spacer(60),
      h2("4.4  HTTPBinEndpoints"),
      ...codeBlock([
        "enum HTTPBinEndpoint {",
        "    case get                    // GET https://httpbin.org/get",
        "    case delay(Int)             // GET https://httpbin.org/delay/{n}",
        "    case status(Int)            // GET https://httpbin.org/status/{code}",
        "    case invalidDomain          // DNS resolution failure",
        "    var url: URL { get }",
        "}",
      ]),
      spacer(60),
      h2("4.5  EngineState"),
      ...codeBlock([
        "@Observable",
        "final class EngineState {",
        "    var isRunning: Bool = false",
        "    var currentScenario: Scenario? = nil",
        "    var stepIndex: Int = 0",
        "    var totalSteps: Int = 0",
        "    var eventsPerSecond: Double = 0",
        "    var mode: AppMode = .manual  // .manual | .auto",
        "}",
        "",
        "enum AppMode { case manual, auto }",
      ]),
      spacer(120),

      // ── S5: FILE STRUCTURE ───────────────────────────────────────────────
      h1("5.  Complete File Structure"),
      p([reg("Generate every file in the table below. Engine, Network, and Logging files must be fully functional. Screen files may stub UI but must compile without errors. All files must be in the group structure shown.")]),
      spacer(80),
      fileTree,
      spacer(120),

      // ── S6: SCENARIO ENGINE ──────────────────────────────────────────────
      h1("6.  Scenario Engine — Implementation Spec"),
      h2("6.1  ScenarioEngine"),
      p([reg("The engine is a Swift actor or class that runs steps sequentially using async/await. The speed multiplier is applied to all delays before scheduling.")]),
      spacer(60),
      ...codeBlock([
        "// Required public interface",
        "final class ScenarioEngine {",
        "    init(state: EngineState, logger: EventLogger)",
        "    func run(scenario: Scenario, speedMultiplier: Double) async",
        "    func stop()",
        "    func reset()",
        "}",
        "",
        "// Step execution loop (pseudo-code)",
        "for (index, step) in scenario.steps.enumerated() {",
        "    guard !isStopped else { break }",
        "    state.stepIndex = index",
        "    await MainActor.run { step.action() }",
        "    logger.log(type: \"step\", scenario: scenario.name, step: index, metadata: [\"label\": step.label])",
        "    let adjustedDelay = step.delay / speedMultiplier",
        "    try? await Task.sleep(nanoseconds: UInt64(adjustedDelay * 1_000_000_000))",
        "}",
      ]),
      spacer(80),
      h2("6.2  LoadGenerator modes"),
      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[2200,7160],
        rows:[
          new TableRow({children:[
            new TableCell({width:{size:2200,type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:"Mode",font:"Arial",size:20,bold:true,color:C.white})])]}),
            new TableCell({width:{size:7160,type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:"Behaviour",font:"Arial",size:20,bold:true,color:C.white})])]}),
          ]}),
          ...([
            ["Burst","Fire X actions in Y seconds using DispatchGroup. Default: 50 actions in 10 seconds."],
            ["Sustained","Continuous moderate rate using a repeating timer. Default: 5 actions/second until stopped."],
            ["Mixed","Interleave navigation pushes, URLSession calls, and button taps in a looping async sequence."],
          ]).map(([m,b],i)=>new TableRow({children:[
            new TableCell({width:{size:2200,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:i%2===0?C.grayLight:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([bold(m,C.teal,20)])]}),
            new TableCell({width:{size:7160,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([reg(b,C.black,20)])]}),
          ]}))
        ]
      }),
      spacer(120),

      // ── S7: PREDEFINED SCENARIOS ─────────────────────────────────────────
      h1("7.  Predefined Scenarios"),
      p([reg("All six scenarios must be defined in Scenarios/ as functions that return a Scenario struct. The ScenarioLibrary.all() class function returns them in order.")]),
      spacer(80),

      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[700,4260,1300],
        rows:[
          scenarioHeader(),
          scenarioRow("S1","Basic Navigation Flow","Navigation",C.blueLight,C.blue,
            "Push A→B→C→D, pop full stack, present modal, dismiss modal.",
            "open(A) · push(B) · push(C) · push(D) · popToRoot · presentModal · dismissModal"),
          scenarioRow("S2","Rapid Interaction Burst","Interaction",C.purpleLight,C.purple,
            "Looped button taps, aggressive scroll, long press, swipe gestures.",
            "tapButton×20 · scrollDown · scrollUp · longPress · swipeLeft · swipeRight"),
          scenarioRow("S3","Network Stress Flow","Network",C.amberLight,C.amber,
            "Fire parallel URLSession calls: fast, slow, server error, DNS fail.",
            "GET /get · GET /delay/3 · GET /status/500 · GET invalidDomain (×10 concurrent)"),
          scenarioRow("S4","Session Restart Flow","Lifecycle",C.tealLight,C.tealDark,
            "Actions → background app → wait 3s → foreground → continue actions.",
            "navigate · background() · wait(3s) · foreground() · navigate"),
          scenarioRow("S5","Cold Start Simulation","Lifecycle",C.tealLight,C.tealDark,
            "Immediate nav + network calls within 500ms of first launch.",
            "launch → push(screen) + GET /get (concurrent, <500ms)"),
          scenarioRow("S6","Mixed Load (Continuous)","Mixed",C.grayLight,C.gray,
            "Navigation + rapid interactions + network combined, loops indefinitely.",
            "S1.steps + S2.steps + S3.steps · loop: true"),
        ]
      }),
      spacer(120),

      // ── S8: PLAYGROUND SPECS ─────────────────────────────────────────────
      h1("8.  Playground Module Specifications"),

      h2("8.1  Navigation Playground"),
      p([reg("Two separate navigation flows must coexist. Both must be driveable by the scenario engine and manually.")]),
      bullet([bold("UIKit flow: ", C.black, 22), reg("UINavigationController with NavLevelViewController instances. Support push/pop up to 10 levels deep. Each level shows its depth number and a button to push the next level.", C.black, 22)]),
      bullet([bold("SwiftUI flow: ", C.black, 22), reg("NavigationStack<[Int], ...> with programmatic push via a path binding. Support the same depth.", C.black, 22)]),
      bullet([bold("Modal: ", C.black, 22), reg("ModalViewController presented as .formSheet. Must have a Dismiss button.", C.black, 22)]),
      spacer(60),

      h2("8.2  Interaction Playground"),
      bullet([bold("Tap burst: ", C.black, 22), reg("A row of 5 UIButtons. The engine calls .sendActions(for: .touchUpInside) in a tight loop.", C.black, 22)]),
      bullet([bold("Scroll: ", C.black, 22), reg("UITableView with 200 rows. Engine animates contentOffset up and down.", C.black, 22)]),
      bullet([bold("Gestures: ", C.black, 22), reg("UILongPressGestureRecognizer (min 0.5s), UISwipeGestureRecognizer (left + right). GestureSimulator fires them programmatically for auto mode.", C.black, 22)]),
      spacer(60),

      h2("8.3  Network Playground"),
      ...codeBlock([
        "// NetworkSimulator — required interface",
        "final class NetworkSimulator {",
        "    init(debugState: DebugPanelViewModel)",
        "    // All requests must go through URLSession.shared",
        "    func fire(_ endpoint: HTTPBinEndpoint) async -> NetworkResult",
        "    func fireParallel(_ endpoints: [HTTPBinEndpoint]) async -> [NetworkResult]",
        "}",
        "",
        "// Debug overrides applied INSIDE the wrapper, not at the call site:",
        "// - delayOverride: prepend URLRequest with /delay/3",
        "// - failureRate: randomly return .clientError without making the request",
      ]),
      spacer(60),
      p([bold("Info.plist requirement: ", C.black, 22), reg("Add NSAppTransportSecurity exception for httpbin.org so HTTP (non-TLS) requests are allowed.", C.black, 22)]),
      spacer(60),

      h2("8.4  Lifecycle Playground"),
      bullet([bold("Background simulation: ", C.black, 22), reg("Call UIApplication.shared.perform(#selector(NSXPCConnection.suspend)) or use XCUIDevice (in test targets only). In the main target, post UIApplication.didEnterBackgroundNotification manually to test observer wiring, and document that real backgrounding requires the user to press Home.", C.black, 22)]),
      bullet([bold("LifecycleObserver: ", C.black, 22), reg("Subscribe to sceneDidBecomeActive, sceneWillResignActive, sceneDidEnterBackground in SceneDelegate and forward each to EventLogger.", C.black, 22)]),
      spacer(60),

      h2("8.5  Crash & Error Playground"),
      banner("SAFETY", "fatalError must be behind a UIAlertController with title 'Trigger crash?' and two actions: 'Cancel' and 'Crash'. Never call fatalError without confirmation.", C.redLight, C.red),
      spacer(60),
      bullet([bold("Crash trigger: ", C.black, 22), mono("fatalError(\"[RUMSimulator] Intentional test crash\")", C.black, 20), reg(" — after confirmation.", C.black, 22)]),
      bullet([bold("UI freeze: ", C.black, 22), mono("Thread.sleep(forTimeInterval: 5)", C.black, 20), reg(" on the main thread to trigger ANR/hang detection.", C.black, 22)]),
      bullet([bold("Non-fatal error: ", C.black, 22), reg("Construct an NSError with domain \"RUMSimulator\" code 42 and log it via EventLogger. This tests the SDK's error surface without crashing.", C.black, 22)]),
      spacer(60),

      h2("8.6  Debug Panel"),
      p([reg("Hidden by default. Revealed by shaking the device (motionEnded(_:with:) in AppDelegate) or a long-press on the app logo.")]),
      spacer(40),
      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[2800,6560],
        rows:[
          new TableRow({children:[
            new TableCell({width:{size:2800,type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:"Control",font:"Arial",size:20,bold:true,color:C.white})])]}),
            new TableCell({width:{size:6560,type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:"Spec",font:"Arial",size:20,bold:true,color:C.white})])]}),
          ]}),
          ...([
            ["Speed multiplier","UISlider 0.5× – 5×. Applied to all ScenarioEngine step delays. Default: 1×."],
            ["Network delay toggle","UISwitch. When ON, all NetworkSimulator requests prepend /delay/3 to the endpoint."],
            ["Failure rate slider","UISlider 0% – 100%. Fraction of requests that return a fake error without hitting the network."],
            ["Force crash button","Calls fatalError after UIAlertController confirmation (same guard as Crash Playground)."],
            ["Force background","Posts UIApplication.didEnterBackgroundNotification to exercise lifecycle observers."],
            ["Reset state","Calls engine.reset(), logger.clear(), and pops all navigation stacks to root."],
          ]).map(([c,s],i)=>new TableRow({children:[
            new TableCell({width:{size:2800,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:i%2===0?C.grayLight:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([bold(c,C.black,20)])]}),
            new TableCell({width:{size:6560,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([reg(s,C.black,20)])]}),
          ]}))
        ]
      }),
      spacer(120),

      // ── S9: LOGGING ──────────────────────────────────────────────────────
      h1("9.  Local Logging System"),
      h2("9.1  EventLogger"),
      ...codeBlock([
        "final class EventLogger {",
        "    // In-memory ring buffer — max 500 events",
        "    private(set) var events: [LogEvent] = []",
        "    private let maxEvents = 500",
        "",
        "    // Async file append — does NOT block the caller",
        "    func log(type: String, scenario: String? = nil, step: Int? = nil, metadata: [String: String] = [:])",
        "",
        "    // Clear in-memory buffer and start a new log file",
        "    func clear()",
        "",
        "    // Returns a URL to the current log file for UIActivityViewController",
        "    func exportURL() throws -> URL",
        "}",
      ]),
      spacer(60),
      h2("9.2  LogFileManager"),
      bullet("One JSON file per scenario run, named rum_log_{scenarioId}_{ISO8601timestamp}.json"),
      bullet("Saved to FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first"),
      bullet("Append mode using JSONEncoder — write the full events array on each flush"),
      bullet("Flush triggered: on scenario end, on app background, and every 30 seconds during long runs"),
      spacer(60),
      h2("9.3  Log Viewer Screen"),
      bullet("UITableView showing LogEvent rows, newest first"),
      bullet("Filter bar with UISegmentedControl: All | Navigation | Tap | Network | Lifecycle | Crash"),
      bullet("Share button: UIActivityViewController presenting the current log file URL"),
      spacer(120),

      // ── S10: CONSTRAINTS ─────────────────────────────────────────────────
      h1("10.  Engineering Constraints"),
      banner("NON-NEGOTIABLE", "Any violation of the constraints below makes the app invalid as a RUM test harness.", C.redLight, C.red),
      spacer(80),

      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[400, 8960],
        rows:[
          ...([
            [C.red, "No SDK API calls anywhere in the codebase. No manual spans, no custom events, no flush calls. The SDK must be linked but never called from app code."],
            [C.red, "URLSession only for all network traffic. Any import of Alamofire, AFNetworking, or equivalent is a build failure."],
            [C.red, "No third-party packages. SPM must reference zero external repositories. CocoaPods must not be used."],
            [C.red, "fatalError must always be guarded by UIAlertController confirmation. Raw fatalError calls outside this guard are forbidden."],
            [C.amber, "All step actions dispatched by ScenarioEngine must run on the main thread (MainActor or DispatchQueue.main)."],
            [C.amber, "Background lifecycle simulation in the main target must use Notification posting only. Private APIs are forbidden."],
            [C.teal, "Deployment target: iOS 16.0. Use @available(iOS 17.0, *) guards for @Observable; fall back to ObservableObject."],
            [C.teal, "No storyboards except LaunchScreen.storyboard. All other UI is programmatic (UIKit) or SwiftUI Views."],
          ]).map(([color, text]) => new TableRow({ children: [
            new TableCell({ width:{size:400,type:WidthType.DXA}, borders:noBorders(), margins:{top:80,bottom:80,left:40,right:40},
              children:[new Paragraph({ children:[new TextRun({text:"!", font:"Arial", size:22, bold:true, color})], alignment:AlignmentType.CENTER, spacing:{before:80} })] }),
            new TableCell({ width:{size:8960,type:WidthType.DXA}, borders:{top:noBorder(),bottom:border(C.rule,4),left:noBorder(),right:noBorder()},
              margins:{top:80,bottom:80,left:80,right:80}, children:[p([reg(text,C.black,20)])] }),
          ]}))
        ]
      }),
      spacer(120),

      // ── S11: SUCCESS CRITERIA ────────────────────────────────────────────
      h1("11.  Success Criteria"),
      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[2000,3680,3680],
        rows:[
          new TableRow({children:[
            ...["Category","Criterion","Verification"].map(t=>new TableCell({width:{size:[2000,3680,3680][["Category","Criterion","Verification"].indexOf(t)],type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:t,font:"Arial",size:20,bold:true,color:C.white})])]}))
          ]}),
          ...([
            ["Functional","All 6 scenarios execute end-to-end without unintended crashes","Run each scenario in Auto mode for 3+ complete loops"],
            ["Functional","Auto mode runs indefinitely (scenario.loop = true) until manually stopped","24-hour sustained run with no memory leak growth"],
            ["Observability","RUM backend shows screen transitions for every navigation step","Compare navigation log vs RUM session replay"],
            ["Observability","Network spans appear for all URLSession requests including failures","Check RUM traces for /get, /delay/3, /status/500, DNS error"],
            ["Observability","Session lifecycle events captured on background/foreground","Trigger S4 — verify session split or continuation in backend"],
            ["Observability","Crash report appears in RUM after Crash Playground trigger","Relaunch after crash and confirm report in dashboard"],
            ["Load","20–50 concurrent URLSession calls without URLSession task queue stall","Run S3 with parallelism=50 for 10 minutes"],
            ["Load","High-frequency tap simulation (≥100 taps/sec) without main thread overflow","Run S2 burst at 5× speed multiplier"],
          ]).map(([cat,crit,ver],i)=>new TableRow({children:[
            new TableCell({width:{size:2000,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:i%2===0?C.grayLight:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([bold(cat,C.black,20)])]}),
            new TableCell({width:{size:3680,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([reg(crit,C.black,20)])]}),
            new TableCell({width:{size:3680,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([muted(ver,18)])]}),
          ]}))
        ]
      }),
      spacer(120),

      // ── S12: BUILD PHASES ────────────────────────────────────────────────
      h1("12.  Build Phases"),
      new Table({
        width:{size:9360,type:WidthType.DXA}, columnWidths:[1400,2400,5560],
        rows:[
          new TableRow({children:[
            ...["Phase","Deliverable","Scope"].map((t,i)=>new TableCell({width:{size:[1400,2400,5560][i],type:WidthType.DXA},borders:allBorders(C.teal,6),shading:{fill:C.tealDark,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:t,font:"Arial",size:20,bold:true,color:C.white})])]}))
          ]}),
          ...([
            ["Phase 1","Foundation","AppDelegate, SceneDelegate, AppCoordinator, PlaygroundCoordinator. UIKit navigation skeleton. SwiftUI NavigationStack root. NetworkSimulator with URLSession + HTTPBinEndpoints. Manual mode only. All playgrounds reachable from ControlPanel."],
            ["Phase 2","Scenario Engine + Core Scenarios","ScenarioEngine, EngineState, ScenarioLibrary. S1 Basic Navigation and S3 Network Stress fully implemented. ControlPanel live readout wired to EngineState. Speed multiplier functional."],
            ["Phase 3","Full Scenario Suite + Load Generator","S2, S4, S5, S6 scenarios. LoadGenerator (burst + sustained + mixed). LifecycleObserver wired to SceneDelegate. CrashPlaygroundVC with confirmation guard."],
            ["Phase 4","Debug Panel + Logging","DebugPanelViewController (shake to reveal). EventLogger with ring buffer and file rotation. LogFileManager with per-run files. LogViewerViewController with filter and export."],
          ]).map(([ph,del,sc],i)=>new TableRow({children:[
            new TableCell({width:{size:1400,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:i%2===0?C.grayLight:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([new TextRun({text:ph,font:"Courier New",size:19,bold:true,color:C.teal})])]}),
            new TableCell({width:{size:2400,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:i%2===0?C.grayLight:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([bold(del,C.black,20)])]}),
            new TableCell({width:{size:5560,type:WidthType.DXA},borders:allBorders(C.rule,4),shading:{fill:C.white,type:ShadingType.CLEAR},margins:{top:80,bottom:80,left:120,right:120},children:[p([reg(sc,C.black,20)])]}),
          ]}))
        ]
      }),
      spacer(200),
      rule(),
      spacer(80),
      p([muted("RUM Scenario Simulator · Technical PRD & Copilot Prompt · v1.0 · iOS 16+ · Swift 5.9+", 18)], { alignment: AlignmentType.CENTER }),
    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/mnt/user-data/outputs/RUM_Simulator_Technical_PRD.docx', buf);
  console.log('Done');
});