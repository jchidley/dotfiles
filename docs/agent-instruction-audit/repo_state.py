#!/usr/bin/env -S uv run python
"""Record metadata-only Git state for repositories owning registry candidates."""
import csv, re, subprocess
from pathlib import Path
OUT=Path('/home/jack/work/agent-instruction-audit')

def run(root,*args):
 p=subprocess.run(['git','-C',root,*args],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
 return p.stdout
roots=set()
with (OUT/'registry.tsv').open() as f:
 for r in csv.DictReader(f,delimiter='\t'):
  if r['owning_repository']: roots.add(r['owning_repository'])
rows=[]
for root in sorted(roots):
 branch=run(root,'branch','--show-current').decode(errors='replace').strip() or '(detached)'
 head=run(root,'rev-parse','--short=12','HEAD').decode(errors='replace').strip()
 status=run(root,'status','--porcelain=v1','-z').split(b'\0')
 status=[x for x in status if x]
 tracked=sum(1 for x in status if not x.startswith(b'??'))
 untracked=sum(1 for x in status if x.startswith(b'??'))
 urls=run(root,'remote','get-url','--all','origin').decode(errors='replace').splitlines()
 cred=sum(1 for u in urls if re.search(r'https?://[^/@\s]+:[^/@\s]+@',u))
 hosts=[]; owners=[]
 for u in urls:
  clean=re.sub(r'^[a-z]+://','',u); clean=re.sub(r'^[^/@]+@','',clean); clean=re.sub(r'^[^/]+:[^/]',lambda m:m.group(0).replace(':','/',1),clean)
  parts=clean.strip('/').removesuffix('.git').split('/')
  if parts: hosts.append(parts[0])
  if len(parts)>=3: owners.append(parts[-2])
 rows.append({'repository':root,'branch':branch,'head':head,'tracked_change_count':tracked,'untracked_count':untracked,'origin_count':len(urls),'credential_bearing_origin_count':cred,'remote_hosts':','.join(sorted(set(hosts))),'remote_owners':','.join(sorted(set(owners)))})
with (OUT/'repository-state.tsv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0].keys(),delimiter='\t',lineterminator='\n'); w.writeheader(); w.writerows(rows)
print(f'Wrote {len(rows)} repository metadata rows; remote URLs and changed paths omitted')
