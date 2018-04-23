-- Copyright (C) 2018 Alexey Kopytov <akopytov@gmail.com>
--
-- This code is licensed under the MIT license, see LICENSE.

--[[

This is a sysbench module implemented to tune hardware and operating systems to
achieve as stable results as possible.

--]]

local ffi=require("ffi")
ffi.cdef[[
int getuid(void);
]]

-- Assert that the script is run on Linux
local function check_linux()
  assert(ffi.os == "Linux", "This profile requires Linux")
end

-- Assert that the script is run by root user
local function check_root()
  assert(ffi.C.getuid() == 0, "You must be root to apply this profile")
end

-- Execute a shell command raising an assertion if it failed
local function exec(command)
  if sysbench.opt.trace then
    print("+ " .. command)
  end
  assert(os.execute(command) == 0, "Failed to execute command: " .. command)
end

-- Protected version of exec() which doesn't raise assertions on failures.
-- Use when the command is allowed to fail
local function pexec(command)
  return pcall(exec, command)
end

-- Set vm.swappinnes to 1
local function set_swappinness()
  exec("sysctl vm.swappiness=1")
end

-- Disable transparent huge pages
local function disable_thp()
  exec("echo never > /sys/kernel/mm/transparent_hugepage/enabled")
  exec("echo never > /sys/kernel/mm/transparent_hugepage/defrag")
end

-- Avoid SYN cookie flood protection in the kernel. This only makes sense when
-- using TCP connections to localhost or on the server machine when running
-- benchmarks over the network
local function tune_network()
  exec("sysctl net.ipv4.tcp_max_syn_backlog=4096")
  exec("sysctl net.core.somaxconn=4096")
end

-- Disable Address Space Layout Randomization (ASLR)
local function disable_aslr()
  exec("sysctl kernel.randomize_va_space=0")
end

local function disable_turbo()
  if ffi.arch ~= "x86" and ffi.arch ~= "x64" then
    print("Don't know how to disable turbo for this architecture")
    return true
  end

  -- First try the intel_pstate method and resort to msr-tools if it is
  -- unavailable
  local no_turbo="/sys/devices/system/cpu/intel_pstate/no_turbo"
  local f=io.open(no_turbo, "w")
  if f then
    f:write("1")
    f:close()
  elseif pexec("which wrmsr > /dev/null 2>&1") == 0 then
    exec("wrmsr -a 0x1a0 0x4000850089")
  else
    error("Cannot disable turbo: neither intel_pstate nor wrmsr are available.")
  end
end

-- Disable scheduler autogrouping
local function disable_sched_autogroup()
  exec("sysctl kernel.sched_autogroup_enabled=0")
end

-- Raise kernel.sched_min_granularity_ns
local function set_sched_min_granularity()
  exec("sysctl kernel.sched_min_granularity_ns=5000000")
end

-- Disable NUMA balancing
local function disable_numa_balancing()
  exec("sysctl kernel.numa_balancing=0")
end

local function set_cpu_governor()
  local governor="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
  local f=io.open(governor, "w")

  if not f then
    print("WARNING: unable to set the CPU governor, because the following " ..
            "file does not exist or is not writable: " .. governor)
    return true
  end

  -- Lua does not provide file globbing, so use shell for this for now
  exec([[
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    if [ -r $cpu/online -a "$(cat $cpu/online 2>/dev/null)" = 1 ]; then
      echo performance > $cpu/cpufreq/scaling_governor
    fi
  done]])
end

local profiles = {
  mysqlbench = {
    description = "Tune system for MySQL benchmarks",
    steps = {
      check_linux,
      check_root,
      set_swappinness,
      disable_thp,
      tune_network,
      disable_sched_autogroup,
      set_sched_min_granularity,
      disable_numa_balancing,
      disable_aslr,
      disable_turbo,
      set_cpu_governor,
    }
  }
}

-- List available profiles
local function list()
  print("The following profiles are available:\n")

  for n, p in pairs(profiles) do
    print(("%-20s %s"):format(n, p.description))
  end

  print()
end

-- Apply a named profile
local function apply()
  local p = sysbench.opt.profile

  assert(p and p ~= "", "apply requires the --profile option")
  assert(profiles[p], "Invalid profile name: " .. p)

  print("Applying profile " .. p .. "...")

  for _, step in ipairs(profiles[p].steps) do
    rc, err = pcall(step)
    assert(rc, err or "Failed to apply profile")
  end

  print("Done.")
end

sysbench.cmdline.options = {
  profile = {"Profile name"},
  trace = {"Trace all executed commands", false}
}

sysbench.cmdline.commands = {
  -- List available profiles
  list = {list, "List available profiles"},
  apply = {apply, "Apply a named profile"},
}
