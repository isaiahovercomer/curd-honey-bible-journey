import json,glob,os,re,collections
O='/workspace/curd-honey/ocr'; R='/workspace/curd-honey/repo'
idx={}; missing=[]
for key in open(f'{O}/keys.txt').read().split():
    n=len(glob.glob(f'{R}/cards/{key}/*.webp'))
    f=f'{O}/{key}.json'
    if not os.path.exists(f): missing.append(key); continue
    d=json.load(open(f,encoding='utf-8'))
    pages=[re.sub(r'\s+',' ',d.get(f'{key}/{p:02d}','')).strip() for p in range(1,n+1)]
    # 每頁最上方視窗列的冊名在整課重複出現，去掉以免每課都被搜到
    firsts=collections.Counter(p.split(' ')[0] for p in pages if p)
    if firsts:
        h,c=firsts.most_common(1)[0]
        if c>=max(3,len(pages)*0.6):
            pages=[p[len(h):].strip() if p.startswith(h+' ') else p for p in pages]
    idx[key]=pages
out={'v':1,'note':'圖卡 OCR 內文（Antigravity CLI / Gemini）；t[key][頁-1]','t':idx}
s=json.dumps(out,ensure_ascii=False,separators=(',',':'))
open(f'{R}/search-index.json','w',encoding='utf-8').write(s)
print('lessons',len(idx),'pages',sum(len(v) for v in idx.values()),'empty',sum(1 for v in idx.values() for p in v if not p),'bytes',len(s.encode()),'missing',missing)
