#!/usr/bin/python
# Tyler Nijmeh <tylernij@gmail.com>

from scipy import interpolate
#!/usr/bin/python
# Tyler Nijmeh <tylernij@gmail.com>

from scipy import interpolate

# P.S.: The default target values are from sdm630 (HMD Opensource)
# P.S.: The default source values are from sdm625 (CAF)

# Target frequencies
target_cluster0_freqs = [787200, 1113600, 1344000, 1516800, 1670400, 1881600, 2016000, 2150400, 2308000]
target_cluster1_freqs = [787200, 1113600, 1344000, 1516800, 1670400, 1881600, 2016000, 2150400, 2308000]

# Source frequencies
src_cluster0_freqs = [652800, 1036800, 1248000, 1401600, 1536000, 2016000, 2150400, 2304000]
src_cluster1_freqs = [652800, 1036800, 1248000, 1401600, 1536000, 2016000, 2150400, 2304000]
# Source costs
src_core0_costs = [5, 10, 13, 16, 19, 36, 43, 54]
src_core1_costs = [5, 10, 13, 16, 19, 36, 43, 54]
src_cluster0_costs = [69, 74, 77, 80, 90, 140, 150, 170]
src_cluster1_costs = [5, 10, 13, 16, 85, 135, 145, 165]

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
