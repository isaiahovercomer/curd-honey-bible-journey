#!/bin/bash
# OCR one lesson's cards via Antigravity CLI; output /workspace/curd-honey/ocr/<key>.json
key="$1"; OUT=/workspace/curd-honey/ocr; G=/workspace/gemini
[ -s "$OUT/$key.json" ] && exit 0
mkdir -p "$G/ocr_in/$key"; files=""; keys=""
for f in /workspace/curd-honey/repo/cards/$key/*.webp; do n=$(basename $f .webp); cp "$f" "$G/ocr_in/$key/$n.webp"; files="$files ocr_in/$key/$n.webp"; keys="$keys \"$key/$n\""; done
prompt="Read these image files one by one with your file-viewing tool:$files . They are Traditional Chinese Bible-study slides. OCR ALL visible text in each image exactly as printed, in Traditional Chinese (do not convert to Simplified, do not correct or paraphrase; keep scripture references like 約三16 and hymn numbers like 補922; keep punctuation). Join wrapped lines naturally; separate distinct text blocks with a single space. Ignore the small 'Curds & Honey' logo and audio-player timestamps. Do not create or edit any files. Output ONLY strict JSON (no code fence, no commentary) with exactly these keys:$keys — format {\"$key/01\": \"text\", ...}"
for attempt in 1 2; do
  cd $G && timeout 900 agy -p "$prompt" --model gemini-4-argon-high --dangerously-skip-permissions > "$OUT/logs/$key.raw" 2>&1
  python3 - "$key" <<'PY' && { rm -rf "$G/ocr_in/$key"; exit 0; }
import json,sys,re
key=sys.argv[1]; O='/workspace/curd-honey/ocr'
t=open(f'{O}/logs/{key}.raw',encoding='utf-8').read()
m=re.search(r'\{.*\}',t,re.S); d=json.loads(m.group(0))
d={k:v for k,v in d.items() if k.startswith(key+'/')}
assert d
json.dump(d,open(f'{O}/{key}.json','w',encoding='utf-8'),ensure_ascii=False,indent=0)
PY
  echo "attempt $attempt failed for $key" >> $OUT/logs/failures.txt; sleep 20
done
exit 1
