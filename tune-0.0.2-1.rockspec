package = "tune"
version = "0.0.2-1"

description = {
  summary = "Tune hardware and OS to improve benchmark stability",
  detailed = [[This is a sysbench module implemented to tune hardware and
operating systems to achieve as stable results as possible. It is inspired by
utilities like tuned, python-perf system Krun. For now the focus is
on MySQL benchmarks on Linux and all settings are based on the author's
personal experience with a particular set of benchmarks, but the goal is
to expand it to work for other software, hardware and operating systems
combinations in the future.]],
  homepage = "https://github.com/sysbench-dev/tune",
  license = "MIT"
}

source = {
  url = "https://github.com/sysbench-dev/tune/archive/0.0.2.tar.gz",
  file = "tune-0.0.2.tar.gz"
}

dependencies = {
  "lua == 5.1"
}

build = {
  type = "builtin",
  modules = {
    tune = "tune.lua"
  }
}
