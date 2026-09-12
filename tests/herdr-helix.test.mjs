import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

const launcher = resolve(import.meta.dirname, "../dot_local/bin/executable_herdr-helix");

function writeCommand(directory, name, body) {
  const file = join(directory, name);
  writeFileSync(file, `#!/usr/bin/env bash\n${body}\n`);
  chmodSync(file, 0o755);
}

function runWithInput(content) {
  const root = mkdtempSync(join(tmpdir(), "herdr-helix-input-"));
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

  const result = spawnSync("/bin/bash", [launcher, "-"], {
    input: content,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${bin}:/usr/bin:/bin`,
      HERDR_ENV: "1",
      HERDR_WORKSPACE_ID: "fixture",
    },
  });
  return { root, result };
}

test("empty stdin fails before creating or opening a Helix tab", () => {
  const root = mkdtempSync(join(tmpdir(), "herdr-helix-"));
  const bin = join(root, "bin");
  const marker = join(root, "herdr-called");
  try {
    mkdirSync(bin);
    writeCommand(bin, "herdr", `touch ${JSON.stringify(marker)}`);
    writeCommand(bin, "jq", "exit 0");

    const result = spawnSync("/bin/bash", [launcher, "-"], {
      input: "",
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${bin}:/usr/bin:/bin`,
        HERDR_ENV: "1",
        HERDR_WORKSPACE_ID: "fixture",
      },
    });

    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stderr, /standard input was empty; the producing command may have failed/);
    assert.equal(result.stdout, "");
    assert.equal(existsSync(marker), false, "Herdr must not be invoked");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("stdin snapshots use an extension matching Markdown, HTML, or plain text", async (t) => {
  const cases = [
    ["Markdown", "<!-- entry:abcd -->\n## USER\n\nhello\n", ".md"],
    ["HTML", "<!doctype html>\n<html><body>hello</body></html>\n", ".html"],
    ["plain text", "ordinary output\n", ".txt"],
  ];

  for (const [name, content, extension] of cases) {
    await t.test(name, () => {
      const { root, result } = runWithInput(content);
      const snapshot = result.stdout.match(/^snapshot=(.+)$/m)?.[1];
      try {
        assert.equal(result.status, 0, result.stderr);
        assert.ok(snapshot, result.stdout);
        assert.equal(snapshot.endsWith(extension), true, snapshot);
        assert.equal(existsSync(snapshot), true, snapshot);
      } finally {
        if (snapshot) rmSync(snapshot, { force: true });
        rmSync(root, { recursive: true, force: true });
      }
    });
  }
});
