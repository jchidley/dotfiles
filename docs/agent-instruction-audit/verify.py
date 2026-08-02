#!/usr/bin/env -S uv run python
"""Integrity checks for the read-only agent-instruction audit outputs."""
import csv, hashlib, subprocess
from pathlib import Path
OUT=Path('/home/jack/work/agent-instruction-audit')
reg=OUT/'registry.tsv'
rows=list(csv.DictReader(reg.open(),delimiter='\t'))
required={'stable_id','path','real_path','type','bytes','lines','sha256','owning_repository','ownership','classification','discovery_mechanism','scope','current_activation','content_summary','unique_information','duplication','apparent_age','verification','risks_count_only','decision','destination_or_archive','validation','commit','review_date'}
checks=[]
def add(name,ok,detail): checks.append((name,ok,detail))
add('registry row count',len(rows)==1016,f'{len(rows)} rows')
add('required columns',required.issubset(rows[0]),f'{len(required & set(rows[0]))}/{len(required)} present')
ids=[r['stable_id'] for r in rows]; paths=[r['path'] for r in rows]
add('stable IDs unique',len(ids)==len(set(ids)),f'{len(set(ids))} unique')
add('paths unique',len(paths)==len(set(paths)),f'{len(set(paths))} unique')
add('decisions complete',all(r['decision'].strip() for r in rows),'all rows')
add('classifications complete',all(r['ownership'].strip() and r['classification'].strip() for r in rows),'all rows')
add('activation complete',all(r['current_activation'].strip() and r['discovery_mechanism'].strip() for r in rows),'all rows')
add('hash/read evidence',all(r['sha256'].strip() and r['bytes'].isdigit() and r['lines'].isdigit() for r in rows),'all rows')
filename=set((OUT/'filename-candidates.txt').read_text().splitlines())
add('conventional filename coverage',filename.issubset(set(paths)),f'{len(filename & set(paths))}/{len(filename)} covered')
additional=set((OUT/'additional-candidates.txt').read_text().splitlines())
add('additional candidate coverage',additional.issubset(set(paths)),f'{len(additional & set(paths))}/{len(additional)} covered')
for script in ['inventory.py','repo_state.py','verify.py']:
 p=subprocess.run(['uv','run','python','-m','py_compile',str(OUT/script)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 add(f'{script} syntax',p.returncode==0,'py_compile')
p=subprocess.run(['bash','-n',str(OUT/'pi-discovery-test.sh')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
add('pi-discovery-test.sh syntax',p.returncode==0,'bash -n')
add('report exists',(OUT/'REPORT.md').stat().st_size>0,f"{(OUT/'REPORT.md').stat().st_size} bytes")
failed=[x for x in checks if not x[1]]
lines=['# Verification','',f"Result: **{'PASS' if not failed else 'FAIL'}**",'', '| Check | Result | Evidence |','|---|---|---|']
for name,ok,detail in checks: lines.append(f"| {name} | {'PASS' if ok else 'FAIL'} | {detail} |")
lines += ['', '## Reproduction', '', '```bash', 'uv run python /home/jack/work/agent-instruction-audit/inventory.py', 'uv run python /home/jack/work/agent-instruction-audit/repo_state.py', '/home/jack/work/agent-instruction-audit/pi-discovery-test.sh', 'uv run python /home/jack/work/agent-instruction-audit/verify.py', '```', '', 'The inventory and scans emit metadata and aggregate counts only; matched secret-like text and remote URL values are never emitted.', '']
(OUT/'VERIFY.md').write_text('\n'.join(lines))
print('PASS' if not failed else 'FAIL')
raise SystemExit(1 if failed else 0)
