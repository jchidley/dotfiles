import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

const launcher = resolve(import.meta.dirname, "../dot_local/bin/executable_herdr-helix");

function writeCommand(directory, name, body) {
  const file = join(directory, name);
  writeFileSync(file, `#!/usr/bin/env bash\n${body}\n`);
  chmodSync(file, 0o755);
}

function fixture() {
  const root = mkdtempSync(join(tmpdir(), "herdr-helix-"));
  const bin = join(root, "bin");
  const calls = join(root, "herdr-calls");
  mkdirSync(bin);
  writeCommand(bin, "herdr", [
    `printf '%s\\t' "$@" >> ${JSON.stringify(calls)}`,
    `printf '\\n' >> ${JSON.stringify(calls)}`,
    `case "$1 $2" in`,
    `  "tab list") printf '%s\\n' '{"result":{"tabs":[{"label":"helix","tab_id":"t1"}]}}' ;;`,
    `  "pane list") printf '%s\\n' '{"result":{"panes":[{"tab_id":"t1","pane_id":"p1"}]}}' ;;`,
    `  "pane process-info") printf '%s\\n' '{"result":{"process_info":{"foreground_processes":[{"name":"hx"}],"shell_pid":123}}}' ;;`,
    `  *) printf '%s\\n' '{}' ;;`,
    `esac`,
  ].join("\n"));
  return { root, bin, calls };
}

function run(context, args, input = "") {
  return spawnSync("/bin/bash", [launcher, ...args], {
    input,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${context.bin}:/usr/bin:/bin`,
      HERDR_ENV: "1",
      HERDR_WORKSPACE_ID: "fixture",
    },
  });
}

function callLines(context) {
  return existsSync(context.calls)
    ? readFileSync(context.calls, "utf8").replace(/\n$/, "").split("\n")
    : [];
}

test("stdin requires an explicit valid extension and rejects empty input before Herdr calls", async (t) => {
  await t.test("missing extension", () => {
    const context = fixture();
    try {
      const result = run(context, ["-"]);
      assert.equal(result.status, 2, result.stderr);
      assert.match(result.stderr, /stdin requires one file extension/);
      assert.deepEqual(callLines(context), []);
    } finally {
      rmSync(context.root, { recursive: true, force: true });
    }
  });

  await t.test("invalid extension", () => {
    const context = fixture();
    try {
      const result = run(context, ["-", "../md"]);
      assert.equal(result.status, 2, result.stderr);
      assert.match(result.stderr, /invalid file extension/);
      assert.deepEqual(callLines(context), []);
    } finally {
      rmSync(context.root, { recursive: true, force: true });
    }
  });

  await t.test("empty input", () => {
    const context = fixture();
    try {
      const result = run(context, ["-", "md"]);
      assert.equal(result.status, 1, result.stderr);
      assert.match(result.stderr, /standard input was empty; the producing command may have failed/);
      assert.deepEqual(callLines(context), []);
    } finally {
      rmSync(context.root, { recursive: true, force: true });
    }
  });
});

test("stdin uses the declared extension without inspecting content", () => {
  const context = fixture();
  let snapshot;
  try {
    const result = run(context, ["-", "md"], "ordinary text with no Markdown markers\n");
    snapshot = result.stdout.match(/^snapshot=(.+)$/m)?.[1];
    assert.equal(result.status, 0, result.stderr);
    assert.ok(snapshot, result.stdout);
    assert.equal(snapshot.endsWith(".md"), true, snapshot);
    assert.equal(existsSync(snapshot), true, snapshot);
    assert.deepEqual(callLines(context).slice(-3), [
      "pane\tsend-keys\tp1\tesc\t",
      `pane\tsend-text\tp1\t:open \"${snapshot}\"\t`,
      "pane\tsend-keys\tp1\tenter\t",
    ]);
  } finally {
    if (snapshot) rmSync(snapshot, { force: true });
    rmSync(context.root, { recursive: true, force: true });
  }
});

test("command and open normalize Helix with Escape before command text and Enter", async (t) => {
  await t.test("command", () => {
    const context = fixture();
    try {
      const result = run(context, ["command", ":write"]);
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(callLines(context).slice(-3), [
        "pane\tsend-keys\tp1\tesc\t",
        "pane\tsend-text\tp1\t:write\t",
        "pane\tsend-keys\tp1\tenter\t",
      ]);
    } finally {
      rmSync(context.root, { recursive: true, force: true });
    }
  });

  await t.test("open", () => {
    const context = fixture();
    const file = join(context.root, "named file.md");
    try {
      writeFileSync(file, "# heading\n");
      const result = run(context, ["open", file]);
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(callLines(context).slice(-3), [
        "pane\tsend-keys\tp1\tesc\t",
        `pane\tsend-text\tp1\t:open \"${file}\"\t`,
        "pane\tsend-keys\tp1\tenter\t",
      ]);
    } finally {
      rmSync(context.root, { recursive: true, force: true });
    }
  });
});
