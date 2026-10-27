"""Geometric readiness checks, including the owner's annotated exclusion and roads.
Only standard library; no renderer or third-party geometry package required.
"""
import json
import math
from pathlib import Path
site=json.loads((Path(__file__).resolve().parents[1]/'data/site.json').read_text())
assert site['units']=='metres'
def footprint(b):
    angle=math.radians(b.get('rotation',0));c,s=math.cos(angle),math.sin(angle)
    points=b.get('outline',[(-b['w']/2,-b['d']/2),(b['w']/2,-b['d']/2),(b['w']/2,b['d']/2),(-b['w']/2,b['d']/2)])
    return [(b['x']+x*c+z*s,b['z']-x*s+z*c) for x,z in points]
def edges(poly):return list(zip(poly,poly[1:]+poly[:1]))
def convex_overlap(a,b):
    for p,q in edges(a)+edges(b):
        axis=(q[1]-p[1],p[0]-q[0]);aa=[x*axis[0]+y*axis[1] for x,y in a];bb=[x*axis[0]+y*axis[1] for x,y in b]
        if max(aa)<=min(bb)+0.01 or max(bb)<=min(aa)+0.01:return False
    return True

def triangles(poly):
    """Ear clipping keeps concave T-shaped courtyards out of collision checks."""
    def turn(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    work=list(poly)
    if sum(a[0]*b[1]-b[0]*a[1] for a,b in edges(work))<0:work.reverse()
    result=[]
    while len(work)>3:
        for i,b in enumerate(work):
            a,c=work[i-1],work[(i+1)%len(work)]
            if turn(a,b,c)<=1e-8:continue
            if any(all(turn(u,v,p)>=-1e-8 for u,v in [(a,b),(b,c),(c,a)]) for j,p in enumerate(work) if j not in [i,(i-1)%len(work),(i+1)%len(work)]):continue
            result.append([a,b,c]);work.pop(i);break
        else:raise AssertionError(('Invalid or self-intersecting building outline',poly))
    result.append(work)
    return result
def overlap(a,b):return any(convex_overlap(ta,tb) for ta in triangles(a) for tb in triangles(b))

def point_distance(p,a,b):
    dx,dy=b[0]-a[0],b[1]-a[1];length=dx*dx+dy*dy
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/length)) if length else 0
    return math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy)
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def segments_cross(a,b,c,d):return cross(a,b,c)*cross(a,b,d)<0 and cross(c,d,a)*cross(c,d,b)<0
def segment_distance(a,b,c,d):
    if segments_cross(a,b,c,d):return 0
    return min(point_distance(p,u,v) for p,u,v in [(a,c,d),(b,c,d),(c,a,b),(d,a,b)])
def inside(p,poly):
    value=False
    for a,b in edges(poly):
        if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:value=not value
    return value
ids=set();bodies=[]
for b in site['buildings']:
    assert b['id'] not in ids,b['id'];ids.add(b['id'])
    assert all(b[k]>0 for k in ['w','d','h']),b
    assert b['source'] and b['confidence'],b
    poly=footprint(b);bodies.append((b,poly))
    for excluded in site['excluded_areas']:
        assert not overlap(poly,excluded['points']),(b['id'],'inside excluded neighbouring parcel')
for i,(a,pa) in enumerate(bodies):
    for b,pb in bodies[i+1:]:assert not overlap(pa,pb),('building overlap',a['id'],b['id'])
road_conflicts=[]
for b,poly in bodies:
    for road in site['roads']:
        for a,c in zip(road['points'],road['points'][1:]):
            dist=min(segment_distance(a,c,u,v) for u,v in edges(poly))
            if inside(a,poly) or inside(c,poly):dist=0
            if dist<road['width']/2-0.15:road_conflicts.append((b['id'],road['id'],round(dist,2)));break
assert not road_conflicts,('paved roads intersect buildings',road_conflicts)
# New video-based stacks/cars must leave both the real footprints and traced
# traffic lanes clear. Walking people are allowed to stand in a service lane.
for prop in site['props']:
    if 'w' not in prop or prop['kind']=='person':continue
    angle=math.radians(prop.get('rotation',0));c,s=math.cos(angle),math.sin(angle)
    ox,oz=prop.get('footprint_offset',[0,0])
    descriptor=dict(prop,x=prop['point'][0]+ox*c+oz*s,z=prop['point'][1]-ox*s+oz*c)
    poly=footprint(descriptor)
    for b,pb in bodies:assert not overlap(poly,pb),('video prop inside building',prop['kind'],prop['point'],b['id'])
    for road in site['roads']:
        for a,b in zip(road['points'],road['points'][1:]):
            distance=min(segment_distance(a,b,u,v) for u,v in edges(poly))
            assert not inside(a,poly) and not inside(b,poly) and distance>=road['width']/2-0.10,('video prop blocks road',prop['kind'],prop['point'],road['id'])
    for excluded in site['excluded_areas']:assert not overlap(poly,excluded['points']),('video prop in excluded neighbours',prop['point'])
for road in site['roads']:
    for excluded in site['excluded_areas']:
        assert not any(inside(point,excluded['points']) for point in road['points']),(road['id'],'road enters excluded parcel')
for zone in site['zones']:
    poly=footprint(zone)
    for road in site['roads']:
        for a,b in zip(road['points'],road['points'][1:]):
            distance=min(segment_distance(a,b,u,v) for u,v in edges(poly))
            assert not inside(a,poly) and not inside(b,poly) and distance>=road['width']/2-0.1,('storage yard covers road',zone['name'],road['id'])
    for b,pb in bodies:assert not overlap(poly,pb),('storage yard inside building',zone['name'],b['id'])
    tower=site['tower_crane']
    distance=min(segment_distance(tower['rail_start'],tower['rail_end'],a,b) for a,b in edges(poly))
    assert distance>=tower['clearance_width']/2-0.1,('stock blocks tower crane travel',zone['name'])
fence_conflicts=[]
for index,fence in enumerate(site['fences']+site.get('open_gate_leaves',[])):
    for a,b in zip(fence,fence[1:]):
        for road in site['roads']:
            distance=min(segment_distance(a,b,u,v) for u,v in zip(road['points'],road['points'][1:]))
            if distance < road['width']/2-0.1:
                fence_conflicts.append((index,road['id'],round(distance,2)))
assert not fence_conflicts,('fence blocks a paved road',fence_conflicts)
scales=[a['pixels']/a['metres'] for a in site['anchors']]
assert max(scales)/min(scales)<1.03,scales
trace=site['trace'];assert abs(trace['warehouse_check']['px_per_m']/trace['lgc_check']['px_per_m']-1)<0.03
by_id={b['id']:b for b in site['buildings']}
assert len(by_id['shop2']['outline'])>=8,'Central shell must retain its stepped T-shaped contour'
central=footprint(by_id['shop2'])
assert not inside((-52,-17),central),'Recessed service court was filled by a bounding rectangle'
assert inside((-57,-24),central) and not inside((-65,-24),central),'The small north step must not turn into a full-width extension'
assert inside((-70,-18),central) and inside((-20,-4),central),'The stem and long central wing must both exist'
assert by_id['shop1']['roof_type']=='hip','Western main roof must have hipped ends, not two gables'
for area in site.get('functional_areas',[]):
    assert inside(area['point'],footprint(by_id[area['parent']])),('Function label outside its physical shell',area['id'])
assert abs(by_id['shop1']['rotation'])==90,'Shop 1 must follow the north/south building axis'
assert by_id['black']['w']>2*by_id['lgc']['w'],'Black workshop scale must match the large eastern map footprint'
assert not ids.intersection(['garage1','garage2','mini','parts','axes']),'Unsupported southern standalone buildings must not return'
print(f"PASS {len(ids)} rotated footprints; no building/road/fence/stock collisions; crane travel clear; exclusion clear; two-source calibration; shop-1 orientation and eastern footprint scale.")
