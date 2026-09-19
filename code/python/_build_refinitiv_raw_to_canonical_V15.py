from pathlib import Path
import zipfile
import xml.etree.ElementTree as ET
import re, csv, math, unicodedata
from collections import Counter

VERSION = "V15.0"

# Stata's `python script` execution does not reliably define Python __file__.
# Resolve the project from the process working directory set by the master DO,
# then search a few parent directories. No machine-specific fallback is used in the public version.
def _resolve_project_root():
    cwd = Path.cwd().resolve()
    candidates = []
    for p in [cwd, cwd.parent, cwd.parent.parent]:
        if p not in candidates:
            candidates.append(p)
    for p in candidates:
        try:
            if p.is_dir() and (p / "Data Mentah").is_dir():
                return p
        except OSError:
            pass
    inspected = " | ".join(str(p) for p in candidates)
    raise FileNotFoundError(
        "Project root could not be resolved. No candidate contains a 'Data Mentah' folder. "
        f"Candidates inspected: {inspected}"
    )

ROOT = _resolve_project_root()
RAW = ROOT / "Data Mentah"
STAGE = ROOT / "00_RAW_STAGING_CSV"
OUTQA = ROOT / "03_FINAL_OUTPUTS" / "FINAL_V7_RAW_STATS" / "00_RAW_QA"
STAGE.mkdir(parents=True, exist_ok=True)
OUTQA.mkdir(parents=True, exist_ok=True)

# Write a version/root handshake before doing expensive raw reconstruction.
with (OUTQA / "PYTHON_HELPER_HANDSHAKE_V15.csv").open("w", encoding="utf-8", newline="") as _hf:
    _hw = csv.writer(_hf)
    _hw.writerow(["helper_version", "root", "cwd", "root_validated"])
    _hw.writerow([VERSION, str(ROOT), str(Path.cwd().resolve()), 1])

# expected STEM, expected company rows, physical cols, drop empty Excel E?, country
SPECS = [
    ("GridExport_August_31_2026_7_49_6",939,1690,False,"Indonesia"),
    ("GridExport_August_31_2026_9_53_53",692,1690,False,"United States"),
    ("GridExport_August_31_2026_10_12_9",874,1691,True,"United States"),
    ("GridExport_August_31_2026_10_16_15",964,1690,False,"United States"),
    ("GridExport_August_31_2026_10_50_32",1308,1690,False,"United States"),
    ("GridExport_August_31_2026_11_4_0",1061,1690,False,"United States"),
    ("GridExport_August_31_2026_11_11_5",784,1690,False,"United States"),
    ("GridExport_August_31_2026_11_45_57",716,1690,False,"United States"),
]
AUDITED_DUPLICATE_STEMS = {
    "GridExport_August_31_2026_10_18_28": "GridExport_August_31_2026_10_16_15",
    "GridExport_August_31_2026_11_31_4": "GridExport_August_31_2026_11_45_57",
}

CELL_REF=re.compile(r"^([A-Z]+)(\d+)$")
COPY_SUFFIX=re.compile(r"\s*\(\d+\)\s*$")
ZERO_WIDTH=re.compile(r"[\u200b-\u200d\ufeff]")
SELECTED=set()
for a,b in [(1,10),(11,231),(266,418),(470,503),(555,660),(839,923),(941,1127),(1146,1213),(1282,1417),(1435,1690)]:
    SELECTED.update(range(a,b+1))

OUTPUT_COLUMNS=[
"permid_str","identifier_ric","ric","isin","company_name","country","year","fy_end_raw",
"trbc_sector","trbc_indgrp","trbc_industry","source_file","fin_anchor","esg_anchor","target_anchor","gov_anchor","target_type",
"s1_int","s2_int","s123_int","ghg123_abs","ghg123_yoy","target_pct","target_year","target_ann_red",
"clim_policy","clim_commit","clim_riskopp","clim_strategy","clim_riskassess","scenario","risk_integrated","carbon_price_flag","carbon_price","offsets","emiss_trading","phaseout_carbon","policy_consistency","policy_position","ext_audit",
"assets","revenue","net_income","debt","st_debt","lt_debt","int_bearing_liab","current_assets","current_liab","ppe","cash","roa_vendor",
"board_size","female_board","ceo_board","ceo_duality","sust_committee","board_indep","board_indep_policy","esg_score","env_score","emissions_score","policy_emiss_score","target_emiss_score","env_controv_n"]

OWN_PV={
"s123_int":(11,17),"ghg123_abs":(45,17),"ghg123_yoy":(79,17),"target_pct":(130,17),"target_year":(164,17),"target_ann_red":(198,17),
"ext_audit":(623,19),"debt":(839,17),"st_debt":(873,17),"assets":(958,17),"roa_vendor":(1026,17),"env_controv_n":(1180,17),
"board_indep_policy":(1282,17),"board_size":(1316,17),"female_board":(1350,17),"esg_score":(1469,17),"env_score":(1503,17),"emissions_score":(1537,17)}
ESG_VALUE_ONLY={"offsets":266,"emiss_trading":283,"clim_policy":300,"clim_commit":317,"clim_riskopp":334,"clim_strategy":351,"clim_riskassess":368,"scenario":385,"risk_integrated":402,"carbon_price_flag":470,"carbon_price":487,"phaseout_carbon":555,"policy_consistency":589,"policy_position":606,"policy_emiss_score":1571,"target_emiss_score":1588,"s1_int":1640,"s2_int":1657}
FIN_VALUE_ONLY={"lt_debt":907,"int_bearing_liab":941,"revenue":992,"net_income":1009,"current_assets":1060,"current_liab":1077,"ppe":1094,"cash":1111}
GOV_VALUE_ONLY={"ceo_board":1384,"ceo_duality":1401,"sust_committee":1435,"board_indep":1622}

def lname(tag): return tag.rsplit("}",1)[-1]
def colint(s):
    x=0
    for ch in s: x=x*26+ord(ch)-64
    return x

def cval(cell):
    if cell.attrib.get("t","")=="inlineStr":
        v="".join((n.text or "") for n in cell.iter() if lname(n.tag)=="t")
    else:
        v=""
        for n in cell:
            if lname(n.tag)=="v": v=n.text or ""; break
    return v.replace("\r"," ").replace("\n"," ").replace("\t"," ").strip()

def yval(v):
    if not v: return None
    s=str(v).strip(); s=s[2:] if s.startswith("FY") else s
    try: y=int(float(s))
    except Exception: return None
    return y if 1900<=y<=2200 else None

def nval(v):
    if v is None or v=="": return None
    try:
        x=float(v); return x if math.isfinite(x) else None
    except Exception: return None

def normalized_stem(path_or_name):
    name = path_or_name.name if isinstance(path_or_name, Path) else str(path_or_name)
    # Remove extension using Path after Unicode normalization.
    name = ZERO_WIDTH.sub("", unicodedata.normalize("NFKC", name)).strip()
    stem = Path(name).stem.strip()
    stem = COPY_SUFFIX.sub("", stem).strip()
    # Download managers sometimes introduce spaces around the basename; ignore them.
    stem = re.sub(r"\s+", "", stem)
    return stem.casefold()

def sheet_fingerprint(path):
    with zipfile.ZipFile(path) as z:
        if "xl/worksheets/sheet1.xml" not in z.namelist():
            raise RuntimeError(f"{path.name}: valid XLSX ZIP opened but sheet1.xml is absent")
        info=z.getinfo("xl/worksheets/sheet1.xml")
        return f"{info.CRC:08x}:{info.file_size}:{info.compress_size}"

def discover_partition(expected_stem):
    if not RAW.exists() or not RAW.is_dir():
        raise FileNotFoundError(f"Raw folder not found: {RAW}")
    key=normalized_stem(expected_stem+".xlsx")
    all_xlsx=[p for p in RAW.iterdir() if p.is_file() and p.suffix.lower()==".xlsx"]
    candidates=[p for p in all_xlsx if normalized_stem(p)==key]
    if not candidates:
        visible="\n  - ".join(sorted(p.name for p in all_xlsx))
        raise FileNotFoundError(
            f"No workbook resolved for expected partition stem: {expected_stem}\n"
            f"XLSX files visible in {RAW}:\n  - {visible if visible else '[none]'}"
        )
    if len(candidates)==1:
        return candidates[0], "unique_match", []
    # Multiple copy-suffixed versions are allowed ONLY when sheet1 content is identical.
    fp={p:sheet_fingerprint(p) for p in candidates}
    if len(set(fp.values()))!=1:
        detail="\n".join(f"  - {p.name}: {h}" for p,h in sorted(fp.items(), key=lambda x:x[0].name.lower()))
        raise RuntimeError(
            f"Ambiguous non-identical copies for {expected_stem}; refusing to choose silently:\n{detail}"
        )
    exact=[p for p in candidates if p.name.casefold()==(expected_stem+".xlsx").casefold()]
    chosen=exact[0] if exact else sorted(candidates,key=lambda p:(len(p.name),p.name.casefold()))[0]
    ignored=[p.name for p in candidates if p!=chosen]
    return chosen, "identical_copy_suffixes_resolved", ignored

def iter_records(path, expected_rows, physical_cols, drop_e):
    data_no=0; maxcol=0
    try:
        zf=zipfile.ZipFile(path)
    except zipfile.BadZipFile as e:
        raise RuntimeError(f"{path.name}: file is not a valid XLSX/ZIP workbook") from e
    with zf as z, z.open("xl/worksheets/sheet1.xml") as sh:
        rowno=0
        for _,elem in ET.iterparse(sh,events=("end",)):
            if lname(elem.tag)!="row": continue
            rowno+=1
            if rowno<=3: elem.clear(); continue
            rec={}
            for cell in elem:
                if lname(cell.tag)!="c": continue
                m=CELL_REF.match(cell.attrib.get("r",""))
                if not m: continue
                p=colint(m.group(1)); maxcol=max(maxcol,p)
                if drop_e:
                    if p==5: continue
                    cp=p if p<5 else p-1
                else: cp=p
                if cp in SELECTED:
                    v=cval(cell)
                    if v!="": rec[cp]=v
            data_no+=1; yield rec; elem.clear()
    if data_no!=expected_rows: raise RuntimeError(f"{path.name}: company rows={data_no}, expected={expected_rows}")
    if maxcol!=physical_cols: raise RuntimeError(f"{path.name}: max physical column={maxcol}, expected={physical_cols}")

def period_list(rec,start,n): return [yval(rec.get(start+j)) for j in range(n)]
def choose_calendar(rec,cands,n_default=17):
    for label,start,n in cands:
        ys=period_list(rec,start,n)
        if any(y is not None for y in ys): return label,ys
    return "",[None]*n_default

def own_map_num(rec,start,n):
    out={}; ys=period_list(rec,start,n)
    for j,y in enumerate(ys):
        if y is not None: out[y]=nval(rec.get(start+n+j))
    return out

def slot_map_num(rec,start,ys):
    out={}
    for j,y in enumerate(ys):
        if y is not None: out[y]=nval(rec.get(start+j))
    return out

def slot_map_str(rec,start,ys):
    out={}
    for j,y in enumerate(ys):
        if y is not None: out[y]=str(rec.get(start+j,"")).strip()
    return out

def main():
    # Resolve names first. Filename is not trusted as evidence of correct content.
    resolved=[]
    for stem,nr,nc,de,country in SPECS:
        path,status,ignored=discover_partition(stem)
        fp=sheet_fingerprint(path)
        resolved.append((stem,path,nr,nc,de,country,status,ignored,fp))

    # Optional audited duplicate-partition copies may exist; never append them.
    extras=[]
    for p in RAW.iterdir():
        if not (p.is_file() and p.suffix.lower()==".xlsx"): continue
        nk=normalized_stem(p)
        for dup,ret in AUDITED_DUPLICATE_STEMS.items():
            if nk==normalized_stem(dup+".xlsx"):
                extras.append((p,dup,ret))

    # Verify no resolved production partition duplicates another production partition.
    prod_fps=[x[-1] for x in resolved]
    if len(set(prod_fps))!=8:
        raise RuntimeError("Duplicate worksheet content detected among the 8 RESOLVED production partitions")

    # If audited duplicate partitions are present, verify they are truly identical to retained partner.
    resolved_by_stem={stem:(path,fp) for stem,path,*rest,fp in resolved}
    ignored_audited=[]
    for p,dup,ret in extras:
        dupfp=sheet_fingerprint(p)
        retfp=resolved_by_stem[ret][1]
        if dupfp!=retfp:
            raise RuntimeError(f"Audited duplicate stem {dup} is present but content no longer matches retained {ret}: {p.name}")
        ignored_audited.append(p.name)

    inv_path=OUTQA/"RAW_SOURCE_INVENTORY_V15.csv"
    with inv_path.open("w",encoding="utf-8",newline="") as f:
        w=csv.writer(f)
        w.writerow(["helper_version","expected_stem","actual_filename","country","expected_company_rows","physical_columns","drop_empty_E","bytes","sheet1_crc_size_fingerprint","resolution_status","ignored_identical_filename_copies","resolved","content_validated"])
        for stem,path,nr,nc,de,country,status,ignored,fp in resolved:
            w.writerow([VERSION,stem,path.name,country,nr,nc,int(de),path.stat().st_size,fp,status,";".join(ignored),1,1])

    outpath=STAGE/"firm_year_raw_components_V15.csv"
    firm_ids=set(); conflicts=[]; anchors=Counter(); source_rows=Counter(); carbon=Counter()
    with outpath.open("w",encoding="utf-8",newline="") as fout:
        writer=csv.DictWriter(fout,fieldnames=OUTPUT_COLUMNS,quoting=csv.QUOTE_ALL,lineterminator="\n")
        writer.writeheader()
        for stem,path,nr,nc,de,expected_country,status,ignored,fp in resolved:
            local_ids=set()
            for i,rec in enumerate(iter_records(path,nr,nc,de),start=1):
                pid=str(rec.get(6,"")).strip()
                if not pid: raise RuntimeError(f"Missing PermID in {path.name} company row {i}")
                if pid in local_ids: raise RuntimeError(f"Duplicate PermID within {path.name}: {pid}")
                if pid in firm_ids: raise RuntimeError(f"PermID occurs in multiple production partitions: {pid}")
                local_ids.add(pid); firm_ids.add(pid)
                iric=str(rec.get(1,"")).strip(); ric=str(rec.get(4,"")).strip(); company=str(rec.get(2,"")).strip()
                cr=str(rec.get(3,"")).strip()
                country="Indonesia" if cr=="Indonesia" else ("United States" if cr in ("United States","United States of America") else "")
                if country!=expected_country: raise RuntimeError(f"Unexpected country {cr!r} in {path.name}")
                if iric and ric and iric!=ric: conflicts.append([pid,company,iric,ric,path.name])

                # Family-specific calendar hierarchy locked from the raw-data audit.
                fin_label,finyrs=choose_calendar(rec,[("assets",958,17),("debt",839,17),("roa",1026,17)])
                esg_label,esgyrs=choose_calendar(rec,[("esg_score",1469,17),("env_score",1503,17),("emissions_score",1537,17),("ghg123",11,17)])
                targ_label,targyrs=choose_calendar(rec,[("target_pct",130,17),("target_year",164,17),("target_ann_red",198,17)])
                if not targ_label and any(y is not None for y in esgyrs): targ_label,targyrs="esg",list(esgyrs)
                gov_label,govyrs=choose_calendar(rec,[("board_size",1316,17),("board_indep_policy",1282,17)])
                if not gov_label and any(y is not None for y in esgyrs): gov_label,govyrs="esg",list(esgyrs)
                for k,v in [("fin",fin_label),("esg",esg_label),("target",targ_label),("gov",gov_label)]: anchors[(k,v)]+=5

                own={k:own_map_num(rec,st,n) for k,(st,n) in OWN_PV.items()}
                esg={k:slot_map_num(rec,st,esgyrs) for k,st in ESG_VALUE_ONLY.items()}
                fin={k:slot_map_num(rec,st,finyrs) for k,st in FIN_VALUE_ONLY.items()}
                gov={k:slot_map_num(rec,st,govyrs) for k,st in GOV_VALUE_ONLY.items()}
                ttype=slot_map_str(rec,113,targyrs)
                base={"permid_str":pid,"identifier_ric":iric,"ric":ric,"isin":str(rec.get(5,"")).strip(),"company_name":company,"country":country,"fy_end_raw":nval(rec.get(7)),"trbc_sector":str(rec.get(8,"")).strip(),"trbc_indgrp":str(rec.get(9,"")).strip(),"trbc_industry":str(rec.get(10,"")).strip(),"source_file":path.name,"fin_anchor":fin_label,"esg_anchor":esg_label,"target_anchor":targ_label,"gov_anchor":gov_label}
                for year in range(2021,2026):
                    row=dict(base); row["year"]=year; row["target_type"]=ttype.get(year,"")
                    for k,mp in own.items(): row[k]=mp.get(year)
                    for k,mp in esg.items(): row[k]=mp.get(year)
                    for k,mp in fin.items(): row[k]=mp.get(year)
                    for k,mp in gov.items(): row[k]=mp.get(year)
                    if row.get("s1_int") is not None and row.get("s2_int") is not None: carbon[(country,year)]+=1
                    writer.writerow({k:("" if row.get(k) is None else row.get(k)) for k in OUTPUT_COLUMNS})
                    source_rows[stem]+=1

    if len(firm_ids)!=7338: raise RuntimeError(f"Unique firms={len(firm_ids)}, expected=7338")
    if sum(source_rows.values())!=36690: raise RuntimeError(f"Firm-years={sum(source_rows.values())}, expected=36690")
    for stem,nr,*_ in SPECS:
        if source_rows[stem]!=nr*5: raise RuntimeError(f"Source-row guardrail failed for {stem}: {source_rows[stem]} vs {nr*5}")
    if len(conflicts)!=2: raise RuntimeError(f"RIC identifier conflicts={len(conflicts)}, expected=2 unique source rows")

    with (OUTQA/"RIC_IDENTIFIER_CONFLICT_AUDIT_V15.csv").open("w",encoding="utf-8",newline="") as f:
        w=csv.writer(f); w.writerow(["permid_str","company_name","identifier_ric","ric","source_file"]); w.writerows(sorted(conflicts))

    expected_anchor={("fin","assets"):34420,("fin","roa"):70,("fin",""):2200,("esg","esg_score"):16770,("esg",""):19920,("target","target_pct"):9615,("target","target_year"):45,("target","esg"):7110,("target",""):19920,("gov","board_size"):16830,("gov","board_indep_policy"):10,("gov",""):19850}
    for key,exp in expected_anchor.items():
        if anchors.get(key,0)!=exp: raise RuntimeError(f"Anchor {key}: {anchors.get(key,0)}, expected={exp}")
    expected_carbon={("Indonesia",2021):54,("Indonesia",2022):81,("Indonesia",2023):92,("Indonesia",2024):100,("Indonesia",2025):24,("United States",2021):1048,("United States",2022):1211,("United States",2023):1253,("United States",2024):1203,("United States",2025):308}
    for key,exp in expected_carbon.items():
        if carbon.get(key,0)!=exp: raise RuntimeError(f"Carbon coverage {key}: {carbon.get(key,0)}, expected={exp}")

    with (OUTQA/"RAW_RECONSTRUCTION_SUMMARY_V15.txt").open("w",encoding="utf-8") as f:
        f.write(f"RAW RECONSTRUCTION V{VERSION} PASS\n")
        f.write(f"Root: {ROOT}\n")
        f.write("Filename policy: stem-based discovery with copy-suffix normalization; filename alone is never trusted.\n")
        f.write("Input: 8 unique validated Refinitiv/LSEG production partitions\n")
        f.write("Original XLSX files modified: NO\n")
        f.write("Canonical firm-years: 36,690\nUnique firms: 7,338\n")
        f.write("RIC identifier-field source-row audit conflicts: 2\n")
        f.write("Family-specific calendar anchor guardrails: PASS\n")
        f.write("Country-year Scope1+2 coverage guardrails: PASS\n")
        if ignored_audited:
            f.write("Audited duplicate partitions present but verified identical and ignored: "+", ".join(sorted(ignored_audited))+"\n")
        f.write(f"Canonical CSV: {outpath}\n")

    print("V15 RAW RESOLUTION + RECONSTRUCTION PASS")
    for stem,path,*_ in resolved:
        print(f"RESOLVED: {stem} -> {path.name}")
    print(f"Canonical CSV: {outpath}")
    print("36,690 firm-years / 7,338 firms / 8 validated production partitions")

if __name__=="__main__":
    main()
