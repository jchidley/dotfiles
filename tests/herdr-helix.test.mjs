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
