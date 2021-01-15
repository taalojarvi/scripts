#!/usr/bin/python
# Tyler Nijmeh <tylernij@gmail.com>

from scipy import interpolate
#!/usr/bin/python
# Tyler Nijmeh <tylernij@gmail.com>

from scipy import interpolate

# P.S.: The default target values are from sdm660
# P.S.: The default source values are from sdm632

# Target frequencies
target_cluster0_freqs = [614400, 883200, 1094400, 1382400, 1536000, 1728000, 1843200]
target_cluster1_freqs = [614400, 883200, 1094400, 1382400, 1536000, 1728000, 1843200]

# Source frequencies
src_cluster0_freqs = [614400, 883200, 1036800, 1363200, 1536000, 1670400, 1804800]
src_cluster1_freqs = [614400, 883200, 1036800, 1363200, 1536000, 1670400, 1804800]
# Source costs
src_core0_costs = [23, 41, 56, 88, 112, 151, 194]
src_core1_costs = [23, 41, 56, 88, 112, 151, 194]
src_cluster0_costs = [4, 5, 7, 9, 9, 11, 13]
src_cluster1_costs = [4, 5, 7, 9, 9, 11, 13]

# Interpolate
def interp(src_freqs, src_costs, target_freqs):
    # Interpolated values
    interp_target_freqs = []
    interp_src_freqs = []
    interp_src_costs = []

    # Extrapolated values
    extrap_target_freqs = []

    # Sort freqs and costs into either interp or extrap
    max_src_freq = src_freqs[len(src_freqs)-1]
    for idx in range(0, len(target_freqs)):
        if target_freqs[idx] <= max_src_freq:
            interp_target_freqs.append(target_freqs[idx])
            interp_src_freqs.append(src_freqs[idx])
            interp_src_costs.append(src_costs[idx])
        else:
            extrap_target_freqs.append(target_freqs[idx])

    # Use more accurate cubic spline interpolation when target <= source freqs
    c_f = interpolate.interp1d(src_freqs, src_costs, kind='cubic')
    for freq in interp_target_freqs:
        print('%d %.0f' % (freq, c_f(freq)))

    # Use linear spline interpolation if we can't accurately extrapolate the cubic spline
    l_f = interpolate.interp1d(src_freqs, src_costs, kind='slinear', fill_value='extrapolate')
    for freq in extrap_target_freqs:
        print('%d %.0f' % (freq, l_f(freq)))

    # Newline
    print("")

# Interpolate for core0, core1, cluster0, cluster1
print("Energy Model Interpolation Script")
print("By Tyler Nijmeh <tylernij@gmail.com>")
print("")
print("--- CORE0 ---")
interp(src_cluster0_freqs, src_core0_costs, target_cluster0_freqs)
print("--- CORE1 ---")
interp(src_cluster1_freqs, src_core1_costs, target_cluster1_freqs)
print("--- CLUSTER0 ---")
interp(src_cluster0_freqs, src_cluster0_costs, target_cluster0_freqs)
print("--- CLUSTER1 ---")
interp(src_cluster1_freqs, src_cluster1_costs, target_cluster1_freqs)
