///|
test "80 weighted cases against complete alignment-path enumeration" {
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-1.6, 1.2, -1.8, -0.7, -0.5, 1.0],
    }
    let y = { count: 2, dimensions: 2, values: [-0.6, 2.0, -1.0, -1.4], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 8.78)
    near(corrected.value, 8.78)
    for k, expected in [-2.0, -1.6, -1.6, 1.4, 1.0, 4.8] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [2.0, 1.6, 0.6000000000000001, -6.199999999999999] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 1.1973824502035905e-31, 9.85468141511262e-34, 1.0, 4.0480429162675973e-38,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -2.0, -1.6000000000000005, -1.6, 1.4000000000000004, 1.0, 4.8,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [2.0, 1.6, 0.6000000000000001, -6.199999999999999] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [-0.6, 1.6, 1.0], }
    let y = { count: 2, dimensions: 1, values: [-0.9, 0.4], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.5692375399332972)
    near(corrected.value, 2.173338982887512)
    for
      k, expected in [
        0.06613660081020623, 2.4227908006990533, 1.2006077412189473,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-0.6379713010019765, -3.0515638417262303] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.26693169959489693, 0.007472711956605847, 0.9939280170483431, 0.00015993189972296183,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.11147212659739794, 2.0272807889043367, 1.5507822272264722,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-0.2875424632799676, -3.4019926794482394] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [0.7, -1.0], }
    let y = { count: 1, dimensions: 1, values: [2.0], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.69)
    near(corrected.value, 11.076276956099344)
    for k, expected in [-2.6, -6.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [8.6] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-3.144710115235713, -5.455289884764287] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [8.6] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [0.3, 0.4, 0.3, 0.5, 0.3, -1.3, 1.5, -0.4],
    }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-0.9, -1.8, 0.7, -1.6, -0.2, 0.4],
    }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 14.629999999865605)
    near(corrected.value, 14.681653437880515)
    for
      k, expected in [
        2.399999999999013, 4.400000000005454, -0.7999999986658779, 4.200000000161007,
        -0.7999999999969793, 0.5999999999932606, 3.400000001481818, -1.5999999977772736,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.4000000009987357, -4.400000001914243, 1.5999999981839381, -4.800000000473668,
        -3.400000000003176, 1.600000000005464,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0000000000000002, 1.3633044263982747e-12, 1.0341772753579871e-13, 4.1613975828836007e-10,
        0.9999999995824971, 1.3841832477587415e-12, 1.9039803039729096e-17, 0.9999999999983348,
        1.6883773913766775e-12, 6.375869572710054e-59, 9.261360211974842e-10, 1.0000000000000002,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.399999999999013, 4.4644086928847315, -0.7999999986658779, 4.135591307281689,
        -0.7999999995909238, 0.6000000002978426, 3.4000000010757625, -1.5999999980818154,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.4000000009823865, -4.4000000019122, 1.599999998167589, -4.800000000475712,
        -3.400000000003176, 1.600000000005464,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [-1.3, 1.5], }
    let y = { count: 2, dimensions: 1, values: [-0.8, -1.5], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 8.992240956954742)
    near(corrected.value, 9.084674988771225)
    for k, expected in [-0.8099918550318979, 6.000004358679977] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.9999956413200235, -6.190008144968102] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 0.4750203624202553, 9.475391253346931e-07, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-0.8099918378125707, 6.00000434146065] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.7409362455590013, -5.93094874920708] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [-0.5, 2.0], }
    let y = { count: 1, dimensions: 1, values: [0.3], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 3.53)
    near(corrected.value, 3.614225210873927)
    for k, expected in [-1.6, 3.4] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-1.7999999999999998] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-1.3980605337335534, 3.1980605337335533] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-1.7999999999999998] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [1.6, 1.4, -0.8, -0.7], }
    let y = { count: 1, dimensions: 2, values: [0.9, 0.8], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.99)
    near(corrected.value, 5.990000000003632)
    for
      k, expected in [
        1.4000000000000001, 1.1999999999999997, -3.4000000000000004, -3.0,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [2.0, 1.8000000000000003] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        1.3999999999564186, 1.1999999999618658, -3.3999999999564188, -2.999999999961866,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [2.0, 1.8000000000000003] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [-1.7], }
    let y = { count: 4, dimensions: 1, values: [-0.4, -1.8, -1.7, -1.4], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.7899999999999996)
    near(corrected.value, 1.879409639213013)
    for k, expected in [-2.9999999999999996] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.5999999999999996, -0.20000000000000018, 0.0, 0.6000000000000001,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-2.9999999999999996] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.5999999883910285, -0.12038842297571509, 0.08934126407029393, 0.431047170514392,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [0.3], }
    let y = { count: 3, dimensions: 1, values: [-0.5, 1.3, 0.2], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.6500000000000001)
    near(corrected.value, 1.9324019951324862)
    for k, expected in [-0.19999999999999996] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-1.6, 2.0, -0.19999999999999996] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-0.19999999999999996] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.4278147746229521, 1.4078073859446283, 0.22000738867832392,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [1.5, 0.1], }
    let y = { count: 3, dimensions: 1, values: [1.8, 0.0, -0.9], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, -0.18895769423498399)
    near(corrected.value, 1.631917543778632)
    for k, expected in [0.5000868213283972, 1.7430664047723428] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.020755482583187, -1.217758921488949, -2.0461497871949783,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.3513123447111397, 0.009614538998953754, 0.12375161252446679, 0.8191094367776489,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-0.1001975108152785, 2.3433507369160185] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.40606592276390474, -1.1523365652847097, -1.4968825835799353,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [-2.0, -0.2, 1.4, 1.1], }
    let y = { count: 1, dimensions: 1, values: [1.5], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 15.31)
    near(corrected.value, 15.967531684293903)
    for k, expected in [-7.0, -3.4, -0.20000000000000018, -0.7999999999999998] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [11.400000000000002] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -6.858640069681978, -3.2409890498111453, -0.6894420848300552, -0.6109287956768217,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [11.400000000000002] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [1.5], }
    let y = { count: 2, dimensions: 1, values: [1.8, -0.1], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 2.6500000000000004)
    near(corrected.value, 2.6500000000000004)
    for k, expected in [2.6] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.6000000000000001, -3.2] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [2.6] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.5999999999999993, -3.1999999999999993] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [0.9, -0.7, -1.6, 1.6, 1.9, -0.4],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [1.8, -0.7, 0.5, -1.0, -1.6, 1.9, 0.0, 1.1],
    }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 6.951503136683075)
    near(corrected.value, 7.136019352485982)
    for
      k, expected in [
        -1.0000025732053983, 0.5999767640425246, -0.18185136694140025, -0.5430462544016675,
        3.800000159294329, -3.00000010467889,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.8000000000059195, -4.004401354647517e-12, -0.7998503608045356, -0.6001564925014953,
        -1.2055418367515943e-05, 0.600012391769622, -3.6182838029305477, 2.943213695773911,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0000000000000002, 0.9999819078874724, 2.37922485192517e-06, 2.422424682851988e-09,
        8.705041987962241e-13, 3.218226325325746e-05, 0.9999998585356784, 0.05678631294681783,
        1.3673364147670377e-16, 7.903317801257408e-14, 2.275630112715602e-08, 1.0000000000000002,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -1.000051236697987, 0.600021534456406, -0.18180208994299157, -0.5430913753898033,
        3.799999545788509, -2.9999997541046355,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.4721245222826598, -0.07566357178289179, -0.47198816995657183, -0.5244745691162185,
        0.12060823912612106, 0.5396905403533137, -3.7388908105997403, 3.00351719558383,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [0.0, -0.6], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [0.2, 0.5, -1.7, -1.8, -0.6, 1.5],
    }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.350000000000001)
    near(corrected.value, 10.350000000000001)
    for k, expected in [4.2, -4.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.4, 2.2, -3.4, -2.4000000000000004, -1.2, 4.2] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [4.2, -4.0] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.4, 2.2, -3.4, -2.4000000000000004, -1.2, 4.2] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [-1.4, -0.4], }
    let y = { count: 3, dimensions: 1, values: [1.8, 0.2, -2.0], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 12.918372578174651)
    near(corrected.value, 13.274342095961334)
    for k, expected in [-6.994159315249094, 2.149953261340696] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        6.427323097263053, 1.6897363720288014, -3.2728534153834574,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.20844147832267207, 0.06071117948621438, 0.006209794832512041, 0.8522697011635423,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-6.5702762000149235, 1.7260701461065253] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [6.211630125805364, 1.8689248695360894, -3.236348941433056] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-1.5, -1.1, -1.1, -1.8, 1.5, -0.5],
    }
    let y = { count: 2, dimensions: 2, values: [-0.8, 1.6, -1.9, 0.6], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 26.949999999999992)
    near(corrected.value, 26.950150118363673)
    for
      k, expected in [
        -1.3999999999999544, -5.400000000000192, 1.5999999999999994, -4.8, 6.8, -2.1999999999999997,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.4, 5.3999999999999995, -8.400000000000045, 7.000000000000193,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 5.67568523263236e-14, 1.5832142861594858e-23, 0.9999999999999999,
        1.1829733350269655e-65, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -1.3988008543307666, -5.402098504921271, 1.5988008543308116, -4.797901495078921,
        6.8, -2.1999999999999997,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.3999999994447165, 5.399999999495196, -8.399999999444761, 7.000000000504996,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [1.4, -0.6, -0.7], }
    let y = { count: 3, dimensions: 1, values: [1.2, 1.6, -0.4], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 0.13948573126960145)
    near(corrected.value, 1.2307279656426018)
    for
      k, expected in [
        0.13799518722949056, -0.5345366696923199, -0.6013324953512863,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.39703005641786526, 0.5327945426663382, 0.8621094915656428,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.9834886270244776, 0.03649739945535615, 0.0008192923179527918,
        0.03138342903244656, 0.983750324012313, 5.392430922262403e-06, 0.0002852182856047719,
        0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.0443696893426824, -0.508045432305162, -0.5341982348516361,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.14455095353486602, 0.1854114983010462, 0.9570134330479354,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [1.5, -0.6, -0.3, 0.9, -0.4, -0.6],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [0.4, 0.6, 1.2, -0.2, 1.5, -1.2, -0.2, 1.0],
    }
    let options = { ..alignment_options(0.4), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.879999447830767)
    near(corrected.value, 5.9225848025628975)
    for
      k, expected in [
        2.8000040455754593, -2.000003973443449, -0.20000041633825036, -0.1999996173745558,
        -0.4000007142537086, -3.199999888019706,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.19999989889985, 2.3999999577226854, -0.5999995129501036, 0.7999997977184478,
        6.410978359803773e-07, -1.2000001174841894, 0.5999958557686177, 3.4000038408807667,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.9999998867213934, 0.9999998395859943, 1.2098654771767725e-06, 7.182501497897015e-08,
        7.336588135340866e-08, 3.510398481781946e-08, 0.9999998465562002, 3.4070593192433103e-10,
        6.218284014736323e-08, 1.3545355016742826e-07, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.800000090775878, -2.000000677778589, -0.20069505105955443, -0.21048175582646095,
        -0.39930212473282334, -3.189521045232661,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.136479371019477, 2.336479384969867, -0.6275967370945232, 0.7437761443442658,
        -0.0359226772262803, -1.0802558724784506, 0.5999958703567803, 3.4000038220020286,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [0.9, 2.0, -0.3, -1.3], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [0.8, 1.7, -0.2, -0.5, 0.7, -2.0],
    }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 2.24)
    near(corrected.value, 2.2400000000000055)
    for
      k, expected in [
        0.19999999999999996, 0.6000000000000001, -2.2, -0.20000000000000018,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.19999999999999996, -0.6000000000000001, 0.19999999999999996, 1.6, 2.0,
        -1.4,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 2.6619397862628765e-30, 5.803779245475061e-100, 4.5554721685323327e-45,
        1.0, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.19999999999999996, 0.6000000000000001, -2.2, -0.20000000000000018,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.19999999999999996, -0.6000000000000001, 0.2000000000000924, 1.599999999999846,
        1.9999999999999076, -1.3999999999998458,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [-0.6, 1.2, -1.8, -1.1], }
    let y = { count: 2, dimensions: 2, values: [0.8, 0.5, -0.2, 0.0], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 6.036024701470133)
    near(corrected.value, 6.263713171314541)
    for
      k, expected in [
        -2.9343752728159442, 1.803125818447834, -3.2003876852833213, -2.200238575558967,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.800387685283321, -1.399761424441033, 3.334375272815945, 1.796874181552166,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 0.16796909101993093, 7.455486217712329e-05, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -2.9372353190764433, 1.7976440631152113, -3.197527639022822, -2.194756820226344,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.4361117164603114, -1.5818994088525378, 3.6986512416389545, 1.9790121659636708,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [1.9, 0.3, -1.4, 0.2, -1.0, 0.7],
    }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-2.0, 1.8, -0.2, 1.0, -2.0, -1.7],
    }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 26.299932453749417)
    near(corrected.value, 26.301562848134246)
    for
      k, expected in [
        7.799999999999999, -2.9999999999999996, -2.3999994535052624, -1.6000002428871052,
        1.998919624908517, 4.799594859340694,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -7.800000182165078, 3.0000004857735436, 2.4010800107618246, 1.6004048977728673,
        -1.9999999999999998, -4.8,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 5.242884899913394e-22, 1.2109922269191547e-113, 1.5180423248827224e-07,
        0.9999998481959756, 5.730806156892293e-18, 3.8315565034115464e-17, 0.0006752344321767905,
        0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        7.799999999999999, -2.9999999999999996, -2.387166660606279, -1.583959251763376,
        1.9860868320095337, 4.7835538682169645,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -7.800000182165078, 3.0000004857735436, 2.4010800107618246, 1.6004048977728673,
        -1.9999999999999998, -4.8,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [0.4], }
    let y = { count: 2, dimensions: 1, values: [1.6, -1.7], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.8500000000000005)
    near(corrected.value, 5.850018643394751)
    for k, expected in [1.7999999999999998] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [2.4000000000000004, -4.2] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [1.7999999999999998] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [2.399876955888618, -4.199876955888618] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [-2.0, -1.7, -0.2, -0.9], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-1.7, 1.1, 0.1, 1.3, -0.6, -1.2],
    }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 13.107840029990246)
    near(corrected.value, 13.165578013702367)
    for
      k, expected in [
        -0.6010352928475922, -5.601410822625501, 0.20591677866460645, -3.8066938015357232,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.5942211332604419, 5.607705155652744, 0.6008337582428883, 4.4003767461228875,
        -0.7999363773203445, -0.5999772776144087,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.00023135003998491088, 2.272238559122204e-05, 0.0019262889131860742,
        0.9997701467915858, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.5296410233501619, -5.5696800361821985, 0.13452250916717623, -3.8384245879790257,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.720340547643843, 5.621718123223319, 0.4730049316849535, 4.380257961858056,
        -0.7982269651458108, -0.5938714609201516,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [-1.3, 1.6], }
    let y = { count: 2, dimensions: 2, values: [0.2, -0.3, -1.3, 1.8], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.9)
    near(corrected.value, 5.901279507832707)
    for k, expected in [-3.0, 3.4000000000000004] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [3.0, -3.8000000000000003, 0.0, 0.3999999999999999] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-3.0, 3.4000000000000004] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.9961663837359716, -3.7946329372303604, 0.003833616264028422, 0.39463293723036014,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [1.1, 1.7, -2.0, 1.8], }
    let y = { count: 4, dimensions: 1, values: [-0.2, -0.6, 1.8, 0.5], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 8.943852799699389)
    near(corrected.value, 9.238716143662836)
    for
      k, expected in [
        2.6005633894194045, 3.8111600588921486, -2.8014536354016015, 2.6000027824170377,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -6.342116667093989, 2.7309108722550786, 9.007432442851512e-05, -2.599156874812507,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.00018203666236339157, 4.003443119479191e-05, 4.2747586737340124e-07,
        0.9850507432301543, 0.014779750320335653, 0.0001701305875986467, 6.003858975007491e-06,
        0.0002989325512942791, 0.999828368140583, 4.257996165206425e-13, 0.00017160948401480944,
        1.0157762669147793e-12, 5.796693696680759e-07, 0.9998283905157724, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.8696456306165783, 3.5420778176949623, -2.8014536354015873, 2.600002782417036,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -6.5712232521558525, 2.9600210270788776, -0.036858719890311066, -2.562211650359703,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-0.9, 1.9, 1.8, 0.2, -0.7, -1.0],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [-1.4, -1.7, 0.3, -0.2, 1.2, 2.0, -1.7, 1.5],
    }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 26.435132868789406)
    near(corrected.value, 26.445151006420126)
    for
      k, expected in [
        0.9165458752465715, 7.343231076001508, 4.105826458769278, -2.8245610860751147,
        1.9994045036783008, -5.000904495982606,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.0000059743539471, -7.200003547325209, -2.8240489241039954, -0.9181978782299606,
        -1.1977156286757742, 3.600433595233151, -2.000006310560434, 5.000002336378232,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.03412038232384995, 0.0003726704365437044, 5.410809466218655e-09, 9.334725912050886e-07,
        0.9686612505469984, 0.9998586925004668, 9.002718769785923e-07, 9.24024953945924e-11,
        2.295497988003534e-05, 0.00014462802402700174, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.9167507278264818, 7.343102094726927, 4.103336718793049, -2.825528850772975,
        2.0016893910746196, -4.999807750010166,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.9802524795298134, -7.182573993068545, -2.8374778863491037, -0.9201674557926823,
        -1.2050489780548923, 3.5847996871429237, -1.9989974937603416, 5.000176267774518,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [0.5, -0.4, -1.2, 0.4, -1.0, -1.3],
    }
    let y = { count: 1, dimensions: 2, values: [0.7, 0.4], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.07)
    near(corrected.value, 10.07000000000002)
    for
      k, expected in [
        -0.3999999999999999, -1.6, -3.8, 0.0, -3.4, -3.4000000000000004,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [7.6, 5.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.4000000000000015, -1.5999999999999994, -3.799999999999923, -6.41441263286121e-13,
        -3.4000000000000754, -3.3999999999993595,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [7.6, 5.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [-1.5, 0.3], }
    let y = {
      count: 4,
      dimensions: 2,
      values: [0.2, -1.7, -0.5, -1.9, -0.6, -2.0, -1.9, -0.8],
    }
    let options = { ..alignment_options(0.4), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 20.2)
    near(corrected.value, 20.523403765057086)
    for k, expected in [-6.4, 15.2] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        3.4, -4.0, 2.0, -4.3999999999999995, 1.8, -4.6, -0.7999999999999998, -2.2,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-6.4, 15.2] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        3.0907424907461465, -4.089516513173819, 2.2267215219164775, -4.384918643274171,
        1.881136807639597, -4.524273312844857, -0.7986008203022209, -2.201291530707153,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [-1.4, -1.1, 0.8, 1.0], }
    let y = { count: 2, dimensions: 2, values: [1.7, -0.4, -1.7, -1.4], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 22.094702238947313)
    near(corrected.value, 22.094702238947313)
    for
      k, expected in [
        -6.114889361059775, -1.3148893610597754, 4.9999999999985585, 4.8000000000022425,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        6.200000000001441, 1.3999999999977575, -5.085110638940225, -4.885110638940224,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 0.14185106490037452, 8.009502092372876e-13, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -6.114889361059775, -1.3148893610597754, 4.9999999999985585, 4.8000000000022425,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        6.200000000001441, 1.3999999999977575, -5.085110638940225, -4.885110638940224,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [-0.2, 0.6], }
    let y = { count: 1, dimensions: 1, values: [1.7], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 4.82)
    near(corrected.value, 5.180036903571635)
    for k, expected in [-3.8, -2.2] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [6.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-3.3893730651937894, -2.6106269348062106] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [6.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-2.0, 1.8, -1.6, -0.7, -1.1, -0.7],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [0.1, 0.9, -1.1, 1.2, 1.1, -1.8, 2.0, 1.3],
    }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 28.49131631580251)
    near(corrected.value, 28.498916757683865)
    for
      k, expected in [
        -5.850289249581161, 2.900192833054107, -5.034037352672499, 1.700960026361756,
        -6.565962647329405, -3.817018676335297,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        4.2, -1.7999999999999998, 1.7334625785215658, -0.7841341830805659, 5.316826671061499,
        -2.1999999999999997, 6.2, 4.0,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.9168273608784223, 8.750294565536144e-99, 4.244789856625899e-206, 2.3492476411084794e-24,
        0.0831733289404056, 0.9168266710614988, 2.0227541828100144e-74, 9.223338485897061e-42,
        1.7456345998482725e-17, 0.08317332893850116, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -5.850289249581161, 2.900192833054107, -4.963527892011294, 1.700960026361756,
        -6.63647210799061, -3.817018676335297,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        4.199999456117016, -1.7999998640292538, 1.73346312240455, -0.7841343190513119,
        5.316826671061499, -2.1999999999999997, 6.2, 4.0,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [1.0, -0.1, -0.4], }
    let y = { count: 2, dimensions: 1, values: [-1.3, -1.2], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 6.936236296566674)
    near(corrected.value, 7.3674602844997725)
    for
      k, expected in [4.600014697917841, 2.3159476819805525, 1.680329159360204] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-5.638280131383845, -2.9580114078747526] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 3.3404358730288904e-06, 0.39914623834318363, 0.6172712317985962, 0.044627310755669086,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [4.475609325165213, 2.252510432953028, 1.8681717811403553] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-5.572171315596969, -3.0241202236616287] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [-0.7], }
    let y = { count: 3, dimensions: 1, values: [1.6, -1.7, 1.4], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.699999999999998)
    near(corrected.value, 10.724979929164634)
    for k, expected in [-6.799999999999999] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [4.6, -2.0, 4.199999999999999] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-6.799999999999999] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [4.571285886157643, -1.9209309818081426, 4.149645095650499] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [-1.0], }
    let y = { count: 4, dimensions: 1, values: [0.3, -1.0, -1.0, -1.8], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 2.33)
    near(corrected.value, 2.385151763765136)
    for k, expected in [-1.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [2.6, 0.0, 0.0, -1.6] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-1.0] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        2.5999998413663707, -1.3072805341636867e-06, -0.003530478530970718, -1.5964680555548656,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [2.0], }
    let y = { count: 3, dimensions: 1, values: [0.8, -1.6, 1.1], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 15.21)
    near(corrected.value, 15.372215660336572)
    for k, expected in [11.399999999999999] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-2.4, -7.2, -1.7999999999999998] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [11.399999999999999] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.652058425441646, -6.800659262461195, -1.9472823120971587,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [-0.3, 0.6, -1.4, 1.6, 1.2, -1.8, 1.5, 1.7],
    }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-2.0, 0.8, -0.1, -0.4, 0.5, 1.6],
    }
    let options = { ..alignment_options(2.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 8.130273510969497)
    near(corrected.value, 9.008366941905031)
    for
      k, expected in [
        3.378511583184636, -0.3010189984819524, 0.5736004323250753, 2.095891945306498,
        2.5976100064262657, -2.8395426115649594, 2.0945070478103407, 0.32404016889551956,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -4.444846745536953, -0.990411940809466, -2.2015927986818653, 1.8548043366442368,
        -1.9977895255275004, -0.1437628999898771,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999998, 0.05033660901490061, 0.0008461082558767378, 0.8696503245504204,
        0.17611285650645642, 0.003180665847011215, 0.00019781907838171525, 0.9942746674496448,
        0.008021306396818986, 4.485354346606881e-08, 0.029533354323605154, 0.9999999999999998,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.9401699714591096, 0.09747239151326836, 1.0126033584695628, 1.696536397328389,
        2.5981992291755116, -2.824097989952129, 2.0932565106421337, 0.30945970526557737,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -4.16038478866364, -1.16911882820296, -2.368073739054363, 2.423762508706554,
        -2.115770542028316, -0.5340141846587004,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [-0.7, 0.7, 1.0, -0.6], }
    let y = { count: 3, dimensions: 1, values: [-0.3, -1.3, 1.9], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 6.020053962403088)
    near(corrected.value, 9.231125554140444)
    for
      k, expected in [
        -0.432524097085608, 1.5642449703065457, 0.7540833583896533, -4.5600729287108415,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.1161736254539802, -2.9993815564382262, 6.789823878992458,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.33915120145860084, 0.007597219006909469, 0.5310491236325587,
        0.3169449592640063, 0.31901379750608216, 0.36551004453056973, 0.1714005366852397,
        0.5470473478566281, 0.1604178959843652, 0.38298414919984086, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.35391613730738525, 0.9956782854907812, -0.26059626668369096, -3.7632668532147258,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.6652669882336992, -2.400755265067282, 6.740290950401233,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [1.8, 1.8, -0.7, 0.0], }
    let y = { count: 2, dimensions: 2, values: [-1.3, -1.4, -1.3, 1.4], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 22.1699999999916)
    near(corrected.value, 22.1699999999916)
    for
      k, expected in [
        6.199999999999999, 6.3999999999999995, 1.2000000001008206, -2.7999999997647516,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -6.20000000010082, -6.400000000235248, -1.2000000000000002, 2.8,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 3.710471652748776e-43, 8.40171643815298e-11, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        6.199999999999999, 6.3999999999999995, 1.2000000001008206, -2.7999999997647516,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -6.20000000010082, -6.400000000235248, -1.2000000000000002, 2.8,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [-1.2, 2.0, 0.5], }
    let y = { count: 1, dimensions: 1, values: [1.0], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 6.090000000000001)
    near(corrected.value, 6.605103970763893)
    for k, expected in [-4.4, 2.0, -1.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [3.4000000000000004] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -4.352217253285529, 1.3600149522660994, -0.4077976989805703,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [3.4000000000000004] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [-1.5, 1.3, 1.8, 1.2, -2.0, 0.8, -1.7, -1.7],
    }
    let y = {
      count: 3,
      dimensions: 2,
      values: [1.0, -0.3, -0.3, 0.1, -1.6, 1.0],
    }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 21.071521950292983)
    near(corrected.value, 21.294390428049525)
    for
      k, expected in [
        -5.061692848679697, 3.261736397776203, 2.959103583952242, 2.6702076709532028,
        -2.3646495275599535, 0.45683790898947413, -0.2044814001102062, -5.405761799500118,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        4.17079278361378, -4.755029208386162, -0.2651054188282034, -1.9113369148655046,
        0.7660328276120377, 5.6833459450329045,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999996, 0.02570988998075999, 5.4436370631989324e-05, 0.5183285841453595,
        0.5068974326949233, 0.00011891647073363921, 1.975290168238342e-05, 0.5287290186066783,
        0.7085654336089416, 1.5486334242017037e-10, 0.001600499740694444, 0.9999999999999996,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -5.061571028748136, 3.2617327062578525, 2.958978289538097, 2.6702109967319654,
        -2.3635911934363163, 0.4480477777202813, -0.20553625975125975, -5.396971302491337,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        3.8433624508186837, -4.654279639507995, -0.13953713889752714, -1.872337605932596,
        0.9678948804764572, 5.543597067221828,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [0.0, -0.6, 1.4], }
    let y = { count: 4, dimensions: 1, values: [-0.7, -0.9, -0.4, -1.6], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.381259297635607)
    near(corrected.value, 10.140521010712776)
    for
      k, expected in [2.5280796494665854, 0.7949223853952604, 6.629705305291175] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.4495248913920997, -1.342760662589713, -0.4121596782732756, -6.748262107897934,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.5138286401341755, 0.20075207978987078, 0.013308260435366788, 0.24347529089688474,
        0.6460543363328342, 0.8677023727214374, 0.35283783725237877, 0.00019757933636264352,
        0.00657315403228184, 0.16628860098054277, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [2.165963093654848, 1.7472523852760182, 6.039491861222155] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.562652339415783, -0.8981528789056317, -1.6157693011969845, -5.876132820634623,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [-1.9, 1.2], }
    let y = { count: 2, dimensions: 2, values: [1.4, -0.8, 0.4, 0.7], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 20.43)
    near(corrected.value, 20.43)
    for k, expected in [-11.2, 5.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [6.6, -4.0, 4.6, -1.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-11.2, 5.0] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        6.5999999999999845, -3.999999999999977, 4.600000000000015, -1.000000000000023,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [-1.7, -0.4], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [1.9, 0.0, 0.8, -0.2, 1.1, 0.0],
    }
    let options = { ..alignment_options(0.4), feature_weights: [0.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 0.3600000000000001)
    near(corrected.value, 0.8426319209655346)
    for k, expected in [0.0, -2.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.0, 0.8, 0.0, 0.4, 0.0, 0.8] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [0.0, -2.0] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.0, 0.6503111398949707, 0.0, 0.6993777202100587, 0.0, 0.6503111398949707,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [0.0, -0.8, 0.5, -0.1], }
    let y = { count: 3, dimensions: 1, values: [1.9, 1.1, 1.7], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.755002975951763)
    near(corrected.value, 11.164675996340593)
    for
      k, expected in [
        -3.9018787596491027, -3.80015071792129, -1.3303408821495426, -3.6584543450147535,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [3.8004950736871415, 5.088087083468729, 3.8022425475788175] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.04630852286674467, 2.7477249457421416e-09, 9.130827960850924e-05,
        0.9999049270129928, 3.78611240611861e-06, 7.174890895041415e-07, 0.9400960545879752,
        0.08425983653105068, 1.9513638840498447e-12, 0.024355977086228303, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -4.137326809937569, -3.483998149296058, -1.6757911388246187, -3.393708606676443,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [3.4976284685048555, 5.685849260601872, 3.5073469756279603] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [-0.6, -1.5, 0.9, -1.2], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [1.5, 0.3, -1.9, -0.7, 1.5, 1.5],
    }
    let options = { ..alignment_options(2.0), feature_weights: [0.2, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.537988026352791)
    near(corrected.value, 3.355895057455947)
    for
      k, expected in [
        -0.5928343486133448, -1.038317095748802, 0.3186102890072133, -1.28277115695431,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.8784605459957949, 0.8161513649894869, -0.9255568048600304, 0.30876500418452907,
        0.3213203184703671, 1.196171883529096,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.6317037881865817, 0.09680990294091316, 0.1602522749824781, 0.5330989598241144,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.4089907953609762, -1.0015483850983282, 0.13476673575484466, -1.3195398676047838,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.5942432702589683, 0.7421865113889847, -0.4089124668658667, 0.5427523020383433,
        0.08889325621302988, 1.036149439275784,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [0.9, -0.7], }
    let y = { count: 3, dimensions: 1, values: [-0.8, -0.2, 0.8], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 4.274785285084633)
    near(corrected.value, 5.121590828160805)
    for k, expected in [4.189515266891548, -3.685273542589377] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -3.4649165534228814, -0.014469084391645626, 2.9751439135123556,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.3475723547290471, 0.12428043243822252, 0.32458276711440576, 0.7501900960122581,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [3.975265190555257, -3.471023466253086] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -3.0725187580261766, 0.09812553161590444, 2.4701515021081004,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [0.1, 0.8], }
    let y = { count: 1, dimensions: 2, values: [-1.0, 0.0], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.3380000000000003)
    near(corrected.value, 1.3380000000000003)
    for k, expected in [2.2, 0.32000000000000006] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-2.2, -0.32000000000000006] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [2.2, 0.32000000000000006] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-2.2, -0.32000000000000006] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [-1.4, 1.1, 0.0, 1.4, 1.0, 0.1, 0.9, -0.7],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [-1.7, -1.3, 1.4, -1.3, 1.3, -1.5, -0.9, 0.6],
    }
    let options = { ..alignment_options(0.4), feature_weights: [0.0, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 42.80519763579795)
    near(corrected.value, 43.433722137464216)
    for
      k, expected in [
        0.0, 12.000000002199736, 0.0, 13.499999999179074, 0.0, 7.231549975213874,
        0.0, -3.831320686271542,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.0, -16.44282063661378, 0.0, -13.490197157669819, 0.0, -5.639565352693317,
        0.0, 6.672353856655777,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 8.656033798699192e-11, 8.642822889790814e-11, 1.4976992727367683e-11,
        0.312990547256289, 0.6870094526571509, 1.319590139542028e-13, 8.643060233890298e-11,
        0.029844522632511784, 0.5662934041345214, 0.403867293110448, 0.06894154281557734,
        0.002845530075432074, 0.08383857227263596, 0.6021567516710632, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.0, 12.399466421013956, 0.0, 13.100316756888049, 0.0, 7.161090876627407,
        0.0, -3.7606447642082697,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.0, -16.50089815299754, 0.0, -13.846566702752963, 0.0, -5.225118291211162,
        0.0, 6.672353856640525,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-1.3, -0.1, 0.6, 0.1, 1.7, 0.7],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [1.1, 0.6, 1.0, 2.0, 0.8, -0.2, 1.2, -1.9],
    }
    let options = { ..alignment_options(0.1), feature_weights: [0.2, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 3.355185759928824)
    near(corrected.value, 3.361544703972415)
    for
      k, expected in [
        -0.9600031374004404, -0.2800028641847246, -0.26232580244566267, -0.5455930950387821,
        0.4417211017892416, 1.0152002160186044,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.0349364501438532, 0.37482561225488326, 0.02442103777981412, 0.6863237539386613,
        -0.07877451629579336, -0.21067073489201713, -0.19997513357101235, -1.0400828880966257,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0000000000000002, 3.4097672228441067e-06, 4.935657178930333e-10, 5.747296930055517e-22,
        0.4940172233854464, 0.692118775467697, 0.6594810908094293, 0.00010361012078175986,
        0.09944581055515073, 0.30828965457450863, 0.36536945548650823, 1.0000000000000002,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.9594700254886039, -0.2799467471413513, -0.2453208523854493, -0.5360829964610753,
        0.4241830398171918, 1.0056340003975244,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        1.034187565769448, 0.38530949060929626, 0.025165158317402916, 0.6757877248228981,
        -0.07841247518315451, -0.21213701255291267, -0.20033241084683487, -1.03856445967438,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [1.2, -0.7, 1.1, 1.0, 1.8, 1.3],
    }
    let y = { count: 2, dimensions: 2, values: [-0.7, 1.3, 1.0, 2.0], }
    let options = { ..alignment_options(2.0), feature_weights: [0.2, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, -0.5061296273496616)
    near(corrected.value, 2.6350946703648797)
    for
      k, expected in [
        0.7712566810219615, -0.9519651937964813, 0.4335707478528771, -0.3253638118511586,
        0.4442990636256037, -0.28,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.2921306229487506, 0.8679719265538579, -0.35699586955169177, 0.6893570790937821,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.14070851277451954, 0.5664327212821485, 0.6434797132432519, 0.1242990636256036,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.7688077356552583, -0.6766231309856022, 0.5508522599339675, -0.5181047758448828,
        0.3294664969112166, -0.36260109881715485,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -1.092256455694528, 0.9502730542467731, -0.5568700368059143, 0.6070559514008669,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [-1.7, -0.2, 0.2, -0.7], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-0.2, 0.3, 1.6, -0.8, 1.7, 1.6],
    }
    let options = { ..alignment_options(2.0), feature_weights: [0.2, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 14.033706663224333)
    near(corrected.value, 15.015094608292229)
    for
      k, expected in [
        -0.9609313666116914, -1.6896463654658227, -1.049943303472122, -11.875357093089209,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.574401669184352, 3.299947837989003, 0.8353543836651289, -1.2423469934847016,
        0.6011186172343325, 11.50740261405073,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.27258541619496884, 0.0008225126723032325, 0.1599895675978006, 0.8491814897995892,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.7690649444965088, -2.3207859118973446, -1.2418097255873046, -11.244217546657687,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.6614746159703973, 2.6349006070097536, 0.7483208874211756, -0.5671446253326118,
        0.6010791666922406, 11.497247476877888,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [-1.2], }
    let y = { count: 1, dimensions: 1, values: [-0.5], }
    let options = { ..alignment_options(0.4), feature_weights: [0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 0.09799999999999999)
    near(corrected.value, 0.09799999999999999)
    for k, expected in [-0.27999999999999997] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.27999999999999997] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-0.27999999999999997] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.27999999999999997] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [2.0, 1.7, 0.6, -0.8, 2.0, -0.1, 1.0, 1.3],
    }
    let y = {
      count: 4,
      dimensions: 2,
      values: [-2.0, 1.6, 0.2, 1.3, 0.0, 0.0, -1.9, -0.6],
    }
    let options = { ..alignment_options(1.0), feature_weights: [2.5, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 90.5636949058861)
    near(corrected.value, 90.57960535025785)
    for
      k, expected in [
        25.271227690642984, 1.6713840527858739, 2.679906186921762, -6.819281692556562,
        9.999979618476281, -0.5001891733773991, 14.506155022879444, 9.507976921843035,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -20.000000000001016, -0.49999999999905886, -6.100292468284631, 3.179939092785383,
        -11.856976050630372, 2.9601707985192984, -14.500000000004448, -9.50000000000057,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.5856919441169312, 1.9359060317742805e-08, 7.137513472844749e-49,
        7.837074621131244e-14, 0.4143923544673996, 0.6170404926619814, 3.3793446921465535e-20,
        1.5123677543916775e-29, 2.9037015935514064e-05, 0.9999718285328413, 2.281099773109375e-13,
        2.043192494027908e-39, 4.732288508147529e-06, 0.001227218745082378, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        25.27122768208937, 1.671384037511561, 2.69516120067138, -6.811654174546326,
        9.98166544100319, -0.5035338347323065, 14.509214195156527, 9.503694080462019,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -19.9999505378686, -0.5000067448353264, -6.113234928316866, 3.0961413512725966,
        -11.844553890319144, 3.0438265993140536, -14.49952916241586, -9.499851314446271,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [1.0, 0.1, -1.4, 1.4], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [-1.1, 1.4, -0.8, 0.8, -0.3, -1.0],
    }
    let options = { ..alignment_options(2.0), feature_weights: [2.5, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 33.16319087389816)
    near(corrected.value, 33.95574830510296)
    for
      k, expected in [
        10.657564930700826, -6.558696620272556, -9.158504566206652, 14.96287601711219,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -9.804371450905537, 6.499999999999999, 2.8073989741276164, -2.9024127226181893,
        5.497912112283748, -12.001766674221443,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.017275226998285934, 0.0003212134948079241, 0.46375236606297654, 0.9876253390373968,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        10.656481663816779, -6.558109850710364, -9.157421299322605, 14.962289247549998,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -9.40259933391592, 5.696451353579775, 2.4447244437117464, -2.2396127403988633,
        5.45881452571, -11.861018010020544,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [1.9], }
    let y = { count: 2, dimensions: 1, values: [1.0, -0.3], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.649999999999999)
    near(corrected.value, 6.270100415507527)
    for k, expected in [6.199999999999999] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-1.7999999999999998, -4.3999999999999995] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [6.199999999999999] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-2.400742450954125, -3.7992575490458744] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [-1.8, -0.7, 1.5, -1.7, -0.2, 1.2],
    }
    let y = { count: 2, dimensions: 2, values: [1.6, 1.5, -0.3, -1.2], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0, 0.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 10.567258470196823)
    near(corrected.value, 11.248273878039102)
    for
      k, expected in [
        -6.916745552633518, 0.0, 0.8327428003747919, 0.0, -0.22936971724552335, 0.0,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [7.3976132391860885, 0.0, -1.0842407696818386, 0.0] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.03891518421117274, 0.841217609702824, 0.27805175619871025,
        0.11926936590153425, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -6.8821571965044726, 0.0, 0.25203173332225215, 0.0, 0.31675299367797105,
        0.0,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [6.927314547636147, 0.0, -0.6139420781318972, 0.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [0.8, 0.8, -0.3, 1.7, -0.4, 1.4],
    }
    let y = { count: 2, dimensions: 2, values: [0.3, 1.6, -0.2, -0.8], }
    let options = { ..alignment_options(2.0), feature_weights: [0.0, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 12.387229030768129)
    near(corrected.value, 14.15955373518957)
    for
      k, expected in [
        0.0, -3.9999315525282713, 0.0, 0.5052125970177248, 0.0, 10.512704948741865,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.0, 3.9874042785793153, 0.0, -11.005390271810635] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 8.555933966143519e-06, 0.999781545357645, 0.00042574594711223884, 0.48729505125813616,
        1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.0, -2.711540099736861, 0.0, -1.2070946873576038, 0.0, 10.936620780325784,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.0, 3.9784586063027314, 0.0, -10.996444599534051] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [-2.0, 1.4, -0.3, -0.9], }
    let y = { count: 4, dimensions: 1, values: [0.0, -0.5, 0.3, -1.7], }
    let options = { ..alignment_options(2.0), feature_weights: [0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, -5.969585897319858)
    near(corrected.value, 0.7523220313163819)
    for
      k, expected in [
        -1.0483732571981683, 0.8910022406408282, 0.034673882982336784, 0.07799520148391006,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.5730049428324947, -0.2719462882963689, 0.2825698320083755, -0.5389265544534086,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999994, 0.32290476205687196, 0.05877307572471545, 0.00465975247755447,
        0.45134040829574157, 0.5915969545919261, 0.32509435533030806, 0.03677129851614013,
        0.15358700129299777, 0.472611706892809, 0.6608080333526228, 0.31051663319768086,
        0.020347587008194844, 0.13583422819247803, 0.4436378972548819, 0.9999999999999994,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.6594215135976892, 0.23601824722783582, 0.15820695849920718, 0.22049437577955291,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.5000309898484088, -0.10939277267969652, -0.1396852950230577, -0.20625099005456188,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [0.2, -1.0, -1.4, -0.6], }
    let y = { count: 2, dimensions: 2, values: [-1.3, -1.4, -0.3, -0.4], }
    let options = { ..alignment_options(0.4), feature_weights: [2.5, 0.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 8.3439944020144)
    near(corrected.value, 8.344765141847482)
    for k, expected in [7.743844814276722, 0.0, -5.718567327800518, 0.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-7.281432672199481, 0.0, 5.256155185723278, 0.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 0.09753792571068856, 0.43713465560103865, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [7.743843913995526, 0.0, -5.718566427519322, 0.0] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-7.271817524720784, 0.0, 5.246540038244581, 0.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 1, values: [-1.8, -0.2], }
    let y = { count: 3, dimensions: 1, values: [1.0, 1.8, -1.9], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 14.719217162652901)
    near(corrected.value, 14.787716260588285)
    for k, expected in [-5.60000000255315, -0.6638327831234201] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [5.663832784561528, 4.000000001150546, -3.4000000000355035] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 3.595352803147402e-10, 1.7751658169651305e-10, 0.026596993567303332,
        0.999999999640473, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [-5.594700629702002, -0.6691321559745685] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [5.893948207925053, 3.7698845777870096, -3.400000000035492] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [-1.5, -2.0], }
    let y = {
      count: 3,
      dimensions: 2,
      values: [1.5, -1.1, 0.6, 1.8, -0.3, 1.3],
    }
    let options = { ..alignment_options(0.1), feature_weights: [0.0, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 26.139999999999997)
    near(corrected.value, 26.147600419219554)
    for k, expected in [0.0, -15.999999999999998] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.0, 1.7999999999999998, 0.0, 7.6, 0.0, 6.6] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [0.0, -15.999999999999998] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.0, 1.7999999999999998, 0.0, 7.529490539338795, 0.0, 6.670509460661204,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [0.3, -0.1, 0.4, -1.2, -1.2, 0.3],
    }
    let y = { count: 2, dimensions: 2, values: [-0.1, 1.1, -0.1, 2.0], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0, 0.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.5374077366658407)
    near(corrected.value, 1.6439917890977327)
    for
      k, expected in [
        0.8707172190611834, 0.0, 1.0359393446143834, 0.0, -2.2000053550780816, 0.0,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-1.2737672723790703, 0.0, 1.5671160637815853, 0.0] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.08839652382647932, 0.4737726274571526, 0.5621667171572309,
        2.43412640104157e-06, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.9351259119406361, 0.0, 0.971530651702686, 0.0, -2.200005355045837, 0.0,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-1.2737672723790703, 0.0, 1.5671160637815853, 0.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 2, dimensions: 2, values: [1.3, -0.9, 1.0, -0.7], }
    let y = {
      count: 4,
      dimensions: 2,
      values: [0.4, 0.3, 1.0, 1.3, -1.6, -0.5, 2.0, 0.9],
    }
    let options = { ..alignment_options(0.1), feature_weights: [2.5, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 23.03105239319284)
    near(corrected.value, 23.039944277388305)
    for
      k, expected in [
        4.528906882784363, -0.49695870456682634, 8.00004913869346, -1.504594717768488,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -4.500049138693457, 0.48000655182579427, -0.02890688278436302, 0.8015468705095198,
        -13.000000000000002, 0.07999999999999999, 5.0, 0.6400000000000001,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.019271255189575346, 1.844532391722563e-20, 1.3537879277714654e-28,
        1.6379564485631558e-05, 0.9807352074283668, 1.0, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        4.406736566533624, -0.4904429543667869, 8.122219454944197, -1.5111104679685274,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -4.499999035264712, 0.4800132322829604, -0.028956986213108805, 0.8015401900523537,
        -13.000000000000002, 0.07999999999999999, 5.0, 0.6400000000000001,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [1.2], }
    let y = { count: 1, dimensions: 1, values: [1.0], }
    let options = { ..alignment_options(2.0), feature_weights: [2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 0.09999999999999995)
    near(corrected.value, 0.09999999999999995)
    for k, expected in [0.9999999999999998] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-0.9999999999999998] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [0.9999999999999998] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-0.9999999999999998] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [-1.3, 1.9, 1.5], }
    let y = { count: 1, dimensions: 1, values: [1.7], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 9.08)
    near(corrected.value, 9.577466221148981)
    for k, expected in [-6.0, 0.3999999999999999, -0.3999999999999999] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [6.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -5.999699390954599, 0.1476093487984662, -0.14790995784386735,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [6.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [0.8, -1.9, -0.9, 0.4], }
    let y = { count: 2, dimensions: 1, values: [-0.5, -0.6], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 4.459190150586839)
    near(corrected.value, 4.510848132946738)
    for
      k, expected in [
        2.6000000077275107, -2.620492168676848, -0.6157352327363222, 2.000016365880801,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-2.2794131262252684, 0.9156241540301269] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 2.75982519565251e-09, 0.10246080750651357, 0.8975391952533116, 0.04214122329661841,
        0.9700370901650457, 9.092156000441123e-06, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.6000000077275107, -2.6204013770570356, -0.6158259053919376, 2.0000162469166036,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-2.343821819104546, 0.9800328469094048] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [1.1, -0.4, -0.3, 0.2], }
    let y = { count: 3, dimensions: 1, values: [0.2, -1.6, -1.0], }
    let options = { ..alignment_options(1.0), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 2.2884833519840972)
    near(corrected.value, 4.071461425190017)
    for
      k, expected in [
        1.8028920587709398, 0.7625407973302285, 2.016687022898228, 2.6036567388763165,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.781659876936567, -2.9096469834365473, -3.4944697575025967,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0000000000000002, 0.000532701120653451, 3.6839808121397283e-06, 0.6683391649061227,
        0.5623743319572858, 0.1790411654334081, 0.21633312517608602, 0.5205443314658525,
        0.6282892044736411, 0.022114613425348782, 0.0565713163545324, 1.0000000000000002,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        1.438933982524119, 1.253657355851347, 2.310368024250169, 2.182817255250078,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.9608397007716034, -2.3804260747325316, -3.8445108423715757,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [1.1, -0.2, 0.7, 0.9], }
    let y = { count: 2, dimensions: 1, values: [-1.7, 1.5], }
    let options = { ..alignment_options(2.0), feature_weights: [0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, -1.0312055251889514)
    near(corrected.value, 3.425783703211709)
    for
      k, expected in [
        1.0909048628304054, 0.03039113813328953, 0.014279697753556024, -0.17754956328753677,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-1.8397636662942687, 0.8817375308645544] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.1818446073099662, 0.6333778709159703, 0.5141699770827833, 0.28884011149189903,
        0.8218962789958345, 0.06004849683890696, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.8752157267900292, 0.4129654637715391, -0.07834876613868974, -0.2518062889931644,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-1.5722224608342317, 0.6141963254045175] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 3,
      dimensions: 2,
      values: [1.3, -1.3, 2.0, -0.1, 0.6, -1.1],
    }
    let y = { count: 1, dimensions: 2, values: [1.3, -1.2], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0, 2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 4.055)
    near(corrected.value, 4.511161677408325)
    for
      k, expected in [
        0.0, -0.5000000000000004, 1.4, 5.499999999999999, -1.4000000000000001, 0.49999999999999933,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [2.220446049250313e-16, -5.499999999999997] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.15181371540129807, 0.19657790690933818, 0.9557638193558278, 4.304212968465987,
        -1.1075775347571262, 0.9992091246246725,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [2.220446049250313e-16, -5.499999999999997] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [-0.9, 0.2, 1.5, 0.5, -0.7, -0.5, -0.9, 1.9],
    }
    let y = { count: 1, dimensions: 2, values: [-0.4, 1.9], }
    let options = { ..alignment_options(0.1), feature_weights: [0.2, 1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 11.45)
    near(corrected.value, 11.450000403985737)
    for
      k, expected in [
        -0.2, -3.4, 0.76, -2.8, -0.11999999999999998, -4.8, -0.2, 0.0,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-0.24000000000000005, 11.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.19999612447750062, -3.399997577798438, 0.7599961219796353, -2.8000024278785287,
        -0.1199999975021346, -4.7999999943230325, -0.2, -4.27696328792375e-25,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-0.24000000000000005, 11.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [-0.6, -2.0, 1.5, 1.5], }
    let y = { count: 4, dimensions: 1, values: [-0.3, 0.0, 0.8, -0.4], }
    let options = { ..alignment_options(2.0), feature_weights: [2.5], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 17.962495525298486)
    near(corrected.value, 21.471504493441703)
    for
      k, expected in [
        -2.4796547661723016, -9.840096249845644, 5.176283422863301, 11.010184776580136,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        3.130245136180241, 7.078105588228728, -4.511162006313766, -9.563905901520693,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999996, 0.31673545695392424, 0.003946219390069623, 0.0018248595800417911,
        0.19640158915604466, 0.8104381361140638, 0.002596017183248239, 0.003744642539143945,
        0.004331255738052774, 0.2564237772751773, 0.8909816829266022, 0.01007241067514621,
        2.0785555962722164e-05, 0.007107175227980446, 0.4161982549618918, 0.9999999999999996,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -2.9948021876493396, -9.324943218893026, 5.176277813778302, 11.010184776189554,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        3.772294304463509, 7.684952564753529, -6.8414217441671425, -8.482542308475386,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [1.2, 0.4], }
    let y = { count: 1, dimensions: 2, values: [-0.7, 0.9], }
    let options = { ..alignment_options(1.0), feature_weights: [0.0, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 0.05)
    near(corrected.value, 0.05)
    for k, expected in [0.0, -0.2] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [0.0, 0.2] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [0.0, -0.2] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.0, 0.2] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [-0.2], }
    let y = { count: 3, dimensions: 1, values: [-1.6, -1.7, 0.9], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 5.420000000000001)
    near(corrected.value, 5.47165343799748)
    for k, expected in [3.6000000000000005] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-2.8000000000000003, -3.0, 2.2] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [3.6000000000000005] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [-2.864408692879278, -2.9355913071207222, 2.2] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = {
      count: 4,
      dimensions: 2,
      values: [0.9, -0.4, -0.9, -0.8, 0.8, 1.7, 0.6, 1.0],
    }
    let y = { count: 2, dimensions: 2, values: [-0.3, 2.0, -0.1, 1.1], }
    let options = { ..alignment_options(2.0), feature_weights: [0.2, 0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, -0.44889778244427747)
    near(corrected.value, 3.6184159979438353)
    for
      k, expected in [
        0.5421788963928444, -1.0532683445892665, -0.2999692359378561, -1.058601892868429,
        0.43699418529275763, 0.13024731839470227, 0.3229765724392843, -0.08775174715476033,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.54339294365684, 1.759455624595732, -0.45878747453019025, 0.3099190416220219,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.155447240982111, 0.6294090136654924, 0.46534710205668095, 0.389714851130168,
        0.7375545855430101, 0.11937936788690076, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.2908004821751955, -1.0513347146237206, 0.193042554884361, -0.6526623658689945,
        0.20072727626775255, -0.3324980735217855, 0.3176101048597213, -0.03287951220325278,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -0.5174922223306507, 1.6429023786278802, -0.4846881958563795, 0.42647228758987366,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 3, dimensions: 1, values: [0.9, 1.3, 0.2], }
    let y = { count: 3, dimensions: 1, values: [-0.5, 2.0, 0.9], }
    let options = { ..alignment_options(0.4), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 2.6680037456291417)
    near(corrected.value, 2.88161671590123)
    for
      k, expected in [
        2.4625889366663163, -0.8671252667155323, -1.4005813309790978,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -2.8009256731567405, 1.5808133640902624, 1.025229970094792,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        1.0, 0.1533686651516742, 0.05613528848660372, 0.0002571132798318602, 0.8877292174486677,
        0.46846253738150967, 4.667810453177492e-08, 0.00016149898012340493, 1.0,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        2.692075089064791, -1.2308688790094597, -1.266323871083645,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [-2.80092481781277, 1.4834415311135811, 1.1226009477275032] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 2, values: [0.1, 0.7], }
    let y = { count: 2, dimensions: 2, values: [0.6, 0.9, -2.0, 0.2], }
    let options = { ..alignment_options(2.0), feature_weights: [1.0, 0.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 4.66)
    near(corrected.value, 4.725876603133799)
    for k, expected in [3.2, 0.0] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [1.0, 0.0, -4.2, 0.0] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [3.2, 0.0] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [0.834240606288535, 0.0, -4.034240606288535, 0.0] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [1.6, -1.2, -0.6, -0.2], }
    let y = { count: 1, dimensions: 1, values: [0.9], }
    let options = { ..alignment_options(0.4), feature_weights: [0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.6720000000000002)
    near(corrected.value, 2.144867131868196)
    for
      k, expected in [
        0.28, -0.8400000000000001, -0.6000000000000001, -0.44000000000000006,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [1.6] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        0.24995508662386978, -0.7052956301204734, -0.6271173440365839, -0.5175421124668127,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for k, expected in [1.6] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 4, dimensions: 1, values: [-0.3, 1.9, -0.8, 1.9], }
    let y = { count: 4, dimensions: 1, values: [-0.3, 0.7, -1.2, -0.1], }
    let options = { ..alignment_options(0.1), feature_weights: [0.2], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 1.0743171124350614)
    near(corrected.value, 1.094660201008772)
    for
      k, expected in [
        -0.047680817555756934, 0.48008763616285133, 0.07695058540430724, 0.8000000041200306,
      ] {
      near(raw.gradient_x[k], expected)
    }
    for
      k, expected in [
        -6.238001935457637e-05, -0.42562832915979565, -0.16002018069785717, -0.7236465182544248,
      ] {
      near(raw.gradient_y[k], expected)
    }
    for
      k, expected in [
        0.9999999999999999, 0.11928304789071294, 0.00010075120560811835, 4.836041863345478e-05,
        7.237189412056619e-05, 0.99988192313282, 2.167975917593889e-08, 0.00010074863671282033,
        6.536237357650214e-06, 0.011002957981798315, 0.9998992453894533, 0.2729650422194812,
        9.29710255363174e-18, 2.929543358946879e-12, 3.3214712633973933e-09, 0.9999999999999999,
      ] {
      near(raw.alignment[k], expected)
    }
    for
      k, expected in [
        -0.047625805461692074, 0.48003212119393085, 0.07695159111552739, 0.799999501283666,
      ] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        0.04256068910948396, -0.46949221048993994, -0.1254593517848512, -0.7569665349661251,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  {
    let x = { count: 1, dimensions: 1, values: [1.9], }
    let y = { count: 3, dimensions: 1, values: [0.3, 0.2, -1.7], }
    let options = { ..alignment_options(0.1), feature_weights: [1.0], }
    let raw = soft_dtw_with(x, y, options).unwrap()
    let corrected = divergence_with(x, y, options).unwrap()
    near(raw.value, 18.409999999999997)
    near(corrected.value, 18.461653437997477)
    for k, expected in [13.799999999999999] {
      near(raw.gradient_x[k], expected)
    }
    for k, expected in [-3.1999999999999997, -3.4, -7.199999999999999] {
      near(raw.gradient_y[k], expected)
    }
    for k, expected in [1.0, 1.0, 1.0] {
      near(raw.alignment[k], expected)
    }
    for k, expected in [13.799999999999999] {
      near(corrected.gradient_x[k], expected)
    }
    for
      k, expected in [
        -3.264408692879278, -3.335591307120723, -7.199999999999998,
      ] {
      near(corrected.gradient_y[k], expected)
    }
  }
  let x = { count: 1, dimensions: 1, values: [0.3], }
  let y = { count: 3, dimensions: 1, values: [1.7, 0.2, 0.4], }
  let options = { ..alignment_options(2.0), feature_weights: [1.0], }
  let raw = soft_dtw_with(x, y, options).unwrap()
  let corrected = divergence_with(x, y, options).unwrap()
  near(raw.value, 1.9799999999999998)
  near(corrected.value, 3.7365530388034154)
  for k, expected in [-2.8] {
    near(raw.gradient_x[k], expected)
  }
  for k, expected in [2.8, -0.19999999999999996, 0.20000000000000007] {
    near(raw.gradient_y[k], expected)
  }
  for k, expected in [1.0, 1.0, 1.0] {
    near(raw.alignment[k], expected)
  }
  for k, expected in [-2.8] {
    near(corrected.gradient_x[k], expected)
  }
  for
    k, expected in [2.0052624255364693, 0.6764334589740101, 0.11830411548952086] {
    near(corrected.gradient_y[k], expected)
  }
}
