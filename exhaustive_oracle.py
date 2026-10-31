"""Independent small-case oracle: enumerate every monotone alignment path.

This does not reuse the MoonBit forward or reverse dynamic-programming recurrence.
The generated cases verify the local numerical experiment, not production fitness.
"""
import json
import math
import random
import sys
from pathlib import Path

root = Path(__file__).parent

def paths(n, m):
    def visit(i, j, path):
        path = path + [(i, j)]
        if i == n - 1 and j == m - 1:
            yield path
            return
        for di, dj in [(1, 0), (0, 1), (1, 1)]:
            if i + di < n and j + dj < m:
                yield from visit(i + di, j + dj, path)
    return list(visit(0, 0, []))

def reference(x, y, d, gamma, feature_weights):
    n, m = len(x) // d, len(y) // d
    all_paths = paths(n, m)
    costs = [sum(sum(feature_weights[k]*(x[i*d+k] - y[j*d+k])**2 for k in range(d)) for i, j in path) for path in all_paths]
    low = min(costs)
    weights = [math.exp(-(v-low)/gamma) for v in costs]
    z = math.fsum(weights)
    gx, gy, occupancy = [0.0]*len(x), [0.0]*len(y), [0.0]*(n*m)
    for path, weight in zip(all_paths, weights):
        probability = weight / z
        for i, j in path:
            occupancy[i*m+j] += probability
            for k in range(d):
                delta = 2.0 * probability * feature_weights[k] * (x[i*d+k] - y[j*d+k])
                gx[i*d+k] += delta
                gy[j*d+k] -= delta
    return {'value': low-gamma*math.log(z), 'gradient_x': gx, 'gradient_y': gy, 'alignment': occupancy}

rng = random.Random(20261031)
fixtures = []
code = ['///|', 'test "80 weighted cases against complete alignment-path enumeration" {']
def arr(value):
    return '[' + ', '.join(repr(float(v)) for v in value) + ']'

for index in range(80):
    n, m, d = rng.randint(1,4), rng.randint(1,4), rng.randint(1,2)
    x = [rng.randint(-20,20)/10 for _ in range(n*d)]
    y = [rng.randint(-20,20)/10 for _ in range(m*d)]
    gamma = rng.choice([0.1,0.4,1.0,2.0])
    weights = [1.0]*d if index < 40 else [rng.choice([0.0, 0.2, 1.0, 2.5]) for _ in range(d)]
    if not any(weights): weights[0] = 1.0
    xy, xx, yy = reference(x,y,d,gamma,weights), reference(x,x,d,gamma,weights), reference(y,y,d,gamma,weights)
    corrected = {'value':xy['value'] - (xx['value'] + yy['value'])/2,
        'gradient_x':[a - (b+c)/2 for a,b,c in zip(xy['gradient_x'],xx['gradient_x'],xx['gradient_y'])],
        'gradient_y':[a - (b+c)/2 for a,b,c in zip(xy['gradient_y'],yy['gradient_x'],yy['gradient_y'])]}
    fixtures.append({'x':x,'y':y,'dimensions':d,'gamma':gamma,'feature_weights':weights,'raw':xy,'corrected':corrected})
    code += ['  {', f'    let x = {{ count: {n}, dimensions: {d}, values: {arr(x)} }}',
             f'    let y = {{ count: {m}, dimensions: {d}, values: {arr(y)} }}',
             f'    let options = {{ ..alignment_options({gamma}), feature_weights: {arr(weights)} }}',
             f'    let raw = soft_dtw_with(x, y, options).unwrap()',
             f'    let corrected = divergence_with(x, y, options).unwrap()',
             f'    near(raw.value, {xy["value"]})',f'    near(corrected.value, {corrected["value"]})']
    for name, value in [('raw', xy), ('corrected',corrected)]:
        for field in ['gradient_x','gradient_y'] + (['alignment'] if name == 'raw' else []):
            code += [f'    for k, expected in {arr(value[field])} {{', f'      near({name}.{field}[k], expected)', '    }']
    code += ['  }']
code += ['}']
if '--check' in sys.argv:
    saved = json.loads((root/'oracle-fixtures.json').read_text(encoding='utf-8'))
    assert len(saved) == len(fixtures) == 80
    maximum = [0.0]
    def compare(a,b):
        if isinstance(a,dict):
            assert a.keys()==b.keys()
            for key in a: compare(a[key],b[key])
        elif isinstance(a,list):
            assert len(a)==len(b)
            for left,right in zip(a,b): compare(left,right)
        else:
            assert isinstance(a,(int,float)) and isinstance(b,(int,float))
            maximum[0]=max(maximum[0],abs(a-b))
            assert abs(a-b)<=1e-12*(1+abs(b)),(a,b)
    for actual,expected in zip(fixtures,saved):
        for field in ['x','y','dimensions','gamma','feature_weights']:
            assert actual[field]==expected[field],field
        compare(actual['raw'],expected['raw'])
        compare(actual['corrected'],expected['corrected'])
    print(f'Checked 80 independently recomputed path fixtures; maximum absolute difference {maximum[0]:.4g}. Cross-platform libm rounding is tolerated, numerical mismatches are not.')
else:
    (root/'core'/'enumerated_wbtest.mbt').write_text('\n'.join(code)+'\n',encoding='utf-8')
    (root/'oracle-fixtures.json').write_text(json.dumps(fixtures,indent=2)+'\n',encoding='utf-8')
    print('Generated 80 independent weighted exhaustive-alignment cases (raw/corrected values, both gradients, and cell occupancy).')
