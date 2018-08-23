# sysbench tune

This is a sysbench module implemented to tune hardware and operating
systems to achieve as stable results as possible. It is inspired by
utilities
like
[Tuned](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/performance_tuning_guide/chap-red_hat_enterprise_linux-performance_tuning_guide-tuned),
[perf system](https://perf.readthedocs.io/en/latest/cli.html#system-cmd)
and [Krun](https://github.com/softdevteam/krun/). For now the focus is
on MySQL benchmarks on Linux and all settings are based on the author's
personal experience with a particular set of benchmarks, but the goal is
to expand it to work for other software, hardware and operating systems
combinations in the future.

# Installation

The easiest way is to install from [SysbenchRocks](http://rocks.sysbench.io/modules/akopytov/tune):
```
luarocks install --server=http://rocks.sysbench.io tune
```

# Usage

```
# List available profiles
sysbench tune list
# Apply a profile.
# 'mysqlbench' is the only available profile at the moment. 
# Most settings require root.
sudo sysbench tune apply --profile=mysqlbench
```
