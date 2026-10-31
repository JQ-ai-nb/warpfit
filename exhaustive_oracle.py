"""Independent small-case oracle: enumerate every monotone alignment path.

This does not reuse the MoonBit forward or reverse dynamic-programming recurrence.
The generated cases verify the local numerical experiment, not production fitness.
"""
import json
import math
import random
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

def reference(x, y, d, gamma):
    n, m = len(x) // d, len(y) // d
    all_paths = paths(n, m)
    costs = [sum(sum((x[i*d+k] - y[j*d+k])**2 for k in range(d)) for i, j in path) for path in all_paths]
    low = min(costs)
    weights = [math.exp(-(v-low)/gamma) for v in costs]
    z = math.fsum(weights)
    gx, gy, occupancy = [0.0]*len(x), [0.0]*len(y), [0.0]*(n*m)
    for path, weight in zip(all_paths, weights):
        probability = weight / z
        for i, j in path:
            occupancy[i*m+j] += probability
            for k in range(d):
                delta = 2.0 * probability * (x[i*d+k] - y[j*d+k])
                gx[i*d+k] += delta
                gy[j*d+k] -= delta
    return {'value': low-gamma*math.log(z), 'gradient_x': gx, 'gradient_y': gy, 'alignment': occupancy}

rng = random.Random(20261031)
fixtures = []
code = ['///|', 'test "40 cases against complete alignment-path enumeration" {']
def arr(value):
    return '[' + ', '.join(repr(float(v)) for v in value) + ']'

for index in range(40):
    n, m, d = rng.randint(1,4), rng.randint(1,4), rng.randint(1,2)
    x = [rng.randint(-20,20)/10 for _ in range(n*d)]
    y = [rng.randint(-20,20)/10 for _ in range(m*d)]
    gamma = rng.choice([0.1,0.4,1.0,2.0])
    xy, xx, yy = reference(x,y,d,gamma), reference(x,x,d,gamma), reference(y,y,d,gamma)
    corrected = {'value':xy['value'] - (xx['value'] + yy['value'])/2,
        'gradient_x':[a - (b+c)/2 for a,b,c in zip(xy['gradient_x'],xx['gradient_x'],xx['gradient_y'])],
        'gradient_y':[a - (b+c)/2 for a,b,c in zip(xy['gradient_y'],yy['gradient_x'],yy['gradient_y'])]}
    fixtures.append({'x':x,'y':y,'dimensions':d,'gamma':gamma,'raw':xy,'corrected':corrected})
    code += ['  {', f'    let x = {{ count: {n}, dimensions: {d}, values: {arr(x)} }}',
             f'    let y = {{ count: {m}, dimensions: {d}, values: {arr(y)} }}',
             f'    let raw = soft_dtw(x, y, {gamma}).unwrap()',
             f'    let corrected = divergence(x, y, {gamma}).unwrap()',
             f'    near(raw.value, {xy["value"]})',f'    near(corrected.value, {corrected["value"]})']
    for name, value in [('raw', xy), ('corrected',corrected)]:
        for field in ['gradient_x','gradient_y'] + (['alignment'] if name == 'raw' else []):
            code += [f'    for k, expected in {arr(value[field])} {{', f'      near({name}.{field}[k], expected)', '    }']
    code += ['  }']
code += ['}']
(root/'core'/'enumerated_wbtest.mbt').write_text('\n'.join(code)+'\n',encoding='utf-8')
(root/'oracle-fixtures.json').write_text(json.dumps(fixtures,indent=2)+'\n',encoding='utf-8')
print('Generated 40 independent exhaustive-alignment cases (raw/corrected values, both gradients, and cell occupancy).')
