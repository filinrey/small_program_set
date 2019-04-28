#!/usr/bin/env ruby

# This script creates a QEMU command line either for Yocto Image based SCT VM or RCP Image based L2-RT VM.
# QEMU is started, unless option --show is given.
# Please use --help option for more information.

require 'optparse'
require 'pathname'

QEMU_COMMON_OPTS = [
  "-enable-kvm",
  "-cpu host",
  "-show-cursor",
  "-no-reboot",
  "-nographic",
  "-m 81920"
]

# Get user id and name
USER_ID = `id -u`.strip
USER_NAME = `whoami`.strip[0..7]  # tap interfaces don't like long names

# Normalize user id (add leading zeroes)
UID_HEX = "%08x" % USER_ID.to_i

# Create base MAC addresses:
SSH_MAC_BASE = "52:%s:%s:%s:" % [ UID_HEX[0..1], UID_HEX[2..3], UID_HEX[4..5] ]
MAC_BASE     = "50:%s:%s:%s:" % [ UID_HEX[0..1], UID_HEX[2..3], UID_HEX[4..5] ]

# Create base tap device name
TAP_BASE = "t1_" + USER_NAME + "_"

NicOptions = Struct.new(:num, :type, :ports)

class Options
  def initialize
    @options = {
      :cpus => 24,
      :role => "l2rt",
      :image => "",
      :simulate_vf_num => 12,
      :qemu_ifconfig_path => "%s" % Pathname.new(File.dirname(__FILE__)).realpath + "/qemu_ifconfig",
      :trsw_nics => 2,
      :trsw_if_type => "socket",
      :trsw_ports => ["8010","8011"],
      :l1_nics => 2,
      :l1_if_type => "socket",
      :l1_ports => ["8100","8101"],
      :shared_host_dir => "/var/fpwork/" + USER_NAME,
      :show => false
    }
  end

  def readParams(opts)
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: startSctRcpVM.rb [options]"

      opts.on("-cNUM", "--cpus=NUM", Integer, "number of virtual CPUs (default 4).") do |c|
        @options[:cpus] = c
      end

      opts.on("-rROLE", "--role=ROLE", "ROLE: l2rt, sct (default l2rt).") do |r|
        @options[:role] = r
      end

      opts.on("-qIMAGE", "--image=IMAGE", "IMAGE: rcp (for l2rt VM) or yocto (for sct vm) file name. [MANDATORY]") do |q|
        @options[:image] = q
      end

      opts.separator ""
      opts.separator "NICs Configuration: "

      opts.on("--simulate-vf-num=VF_NUM", Integer, "number of simulate VFs (default 12).") do |v|
        @options[:simulate_vf_num] = v
      end

      opts.on("--qemu-ifconfig-path=QEMU_IFCONFIG_PATH", "path to qemu ifconfig files (default <startVM.rb path>/qemu_ifconfig).") do |v|
        @options[:qemu_ifconfig_path] = v
      end

      opts.on("--trsw-nics=NUM_NICS", Integer, "number of TRSW NICs bound to DPDK (default 1).") do |n|
        @options[:trsw_nics] = n
      end

      opts.on("--trsw-if-type=IF_TYPE", "IF_TYPE: tap, socket (default tap).") do |t|
        @options[:trsw_if_type] = t
      end

      opts.on("--trsw-ports [PORT_LIST]", Array, "List of Ports to be used for each trsw NIC.",
                                                 "For e.g. P1, P2, ... Pn for n number of NICs.") do |p|
        @options[:trsw_ports] = p
      end

      opts.on("--l1-nics=NUM_NICS", Integer, "number of L1 NICs bound to DPDK (default 1).") do |n|
        @options[:l1_nics] = n
      end

      opts.on("--l1-if-type=IF_TYPE", "IF_TYPE: tap, socket (default tap)") do |t|
        @options[:l1_if_type] = t
      end

      opts.on("--l1-ports [PORT_LIST]", Array, "List of Ports to be used for each l1 NIC.",
                                               "For e.g. P1, P2, ... Pn for n number of NICs.") do |p|
        @options[:l1_ports] = p
      end

      opts.separator ""

      opts.on("-dDIR", "--shared-host-dir=DIR", "Shared Host Directory, default /var/fpwork/USER_NAME") do |d|
        @options[:shared_host_dir] = d
      end

      opts.on("-s", "--show", "show qemu command line.") do |s|
        @options[:show] = s
      end

    end
    parser.parse!(opts)
  end

  def cpus
    return @options[:cpus]
  end

  def role
    return @options[:role]
  end

  def image
    return @options[:image]
  end

  def simulate_vf_num
    return @options[:simulate_vf_num]
  end

  def qemu_ifconfig_path
    return @options[:qemu_ifconfig_path]
  end

  def trsw_nics
    return @options[:trsw_nics]
  end

  def trsw_if_type
    return @options[:trsw_if_type]
  end

  def trsw_ports
    return @options[:trsw_ports]
  end

  def l1_nics
    return @options[:l1_nics]
  end

  def l1_if_type
    return @options[:l1_if_type]
  end

  def l1_ports
    return @options[:l1_ports]
  end

  def shared_host_dir
    return @options[:shared_host_dir]
  end

  def show
    return @options[:show]
  end
end

def executeQemuCmd(o)
  cmd = "sudo /opt/qemu/x86_64/2.4.0/bin/qemu-system-x86_64"

  QEMU_COMMON_OPTS.each { |cc| cmd += " " + cc }

  cmd += " -smp " + o.cpus.to_s

  if o.role == "l2rt"
    roleId = 0
  elsif o.role == "sct"
    roleId = 1
  else
    puts "ERROR: INVALID role: " + o.role
    exit
  end
  puts "---parse Nics"
  cmd += configureNics(o, roleId)
  puts "---parse Image"
  cmd += configureGuestImage(o.image)
  puts "---parse filesystem"
  cmd += configureVirtfs(o.shared_host_dir)

  puts "Execute QEMU:"
  puts cmd

  # execute command
  if !o.show
    system(cmd)
  end
end

def configureGuestImage(image)
  if image == ""
    puts "ERROR: Image Filename is not provided."
    exit
  end

  # overlayImageFile must be readable/writeable for root
  system("chmod ugo+rw #{image}")

  imageConfig  = String.new
  imageConfig += " -drive file=" + image + ",if=virtio,format=qcow2"
  return imageConfig
end

def configureNics(o, roleId)
  nics  = String.new
  ifIdx = 0
  ifconfigPath = o.qemu_ifconfig_path

  # Configure TAP IF for SSH connection
  # simulate eth0
  nics += configureTapIf(SSH_MAC_BASE, roleId, ifIdx, ifconfigPath)
  ifIdx += 1

  if roleId == 0 # role = "l2rt"
    # simulate eth1
    nics += configureTapIf(SSH_MAC_BASE, roleId, ifIdx, ifconfigPath)
    ifIdx += 1
  end

  # Configure L1 IFs
  # simulate eth2
  if o.l1_if_type == "socket"
    nics += configureSocketIf(MAC_BASE, o.l1_ports[0], roleId, ifIdx)
  else
    nics += configureTapIf(MAC_BASE, roleId, ifIdx, ifconfigPath)
  end
  ifIdx += 1

  # Configure TRSW IFs
  # simulate eth3
  if o.trsw_if_type == "socket"
    nics += configureSocketIf(MAC_BASE, o.trsw_ports[0], roleId, ifIdx)
  else
    nics += configureTapIf(MAC_BASE, roleId, ifIdx, ifconfigPath)
  end
  ifIdx += 1

  if roleId == 0 # role = "l2rt"
    # simulate eth4 / eth5
    nics += configureTapIf(SSH_MAC_BASE, roleId, ifIdx, ifconfigPath)
    ifIdx += 1
    nics += configureTapIf(SSH_MAC_BASE, roleId, ifIdx, ifconfigPath)
    ifIdx += 1
  end

  # Configure L1 IFs
  # simulate eth6
  if o.l1_if_type == "socket"
    nics += configureSocketIf(MAC_BASE, o.l1_ports[1], roleId, ifIdx)
  else
    nics += configureTapIf(MAC_BASE, roleId, ifIdx, ifconfigPath)
  end
  ifIdx += 1

  # Configure TRSW IFs
  # simulate eth7
  if o.trsw_if_type == "socket"
    nics += configureSocketIf(MAC_BASE, o.trsw_ports[1], roleId, ifIdx)
  else
    nics += configureTapIf(MAC_BASE, roleId, ifIdx, ifconfigPath)
  end
  ifIdx += 1

  # Configure App IFs
  if roleId == 0 # role = "l2rt"
    # simulate eth8 - eth17 as VF
    for i in 0...o.simulate_vf_num
      nics += configureTapIf(MAC_BASE, roleId, ifIdx, ifconfigPath)
      ifIdx += 1
    end
  end

  return nics
end

def configureTapIf(macBase, roleId, idx, ifconfigPath)
  netDevModel = "virtio-net-pci"
  vNetDevice = " -device " + netDevModel + ",netdev=hostnet" + idx.to_s + ",id=net" + idx.to_s + ",mac=" + macBase + "%02x:" % roleId + "%02x" % idx
  script_path = ifconfigPath + "/qemu_ifup_" + "%02d" % idx
  if File::exists?(script_path) == true
    netBackend = " -netdev tap,id=hostnet" + idx.to_s + ",ifname=" + TAP_BASE + "%1d" % roleId + "%02d" % idx + ",script=" + script_path + ",downscript=no"
  else
    netBackend = " -netdev tap,id=hostnet" + idx.to_s + ",ifname=" + TAP_BASE + "%1d" % roleId + "%02d" % idx + ",script=no,downscript=no"
  end
  return vNetDevice + netBackend
end

def configureSocketIf(macBase, port, roleId, idx)
  if roleId == 0 # role = "l2rt"
    netDevModel = "virtio-net-pci"
    mode = "listen"
  else
    netDevModel = "e1000"
    mode = "connect"
  end
  socketOption = mode + "=127.0.0.1:"

  vNetDevice = " -device " + netDevModel + ",netdev=hostnet" + idx.to_s + ",id=net" + idx.to_s + ",mac=" + macBase + "%02x:" % roleId + "%02x" % idx
  netBackend = " -netdev socket,id=hostnet" + idx.to_s + "," + socketOption + port.to_s
  return vNetDevice + netBackend
end

def configureVirtfs(sharedHostDir)
  virtfs = " -virtfs local,path=" + sharedHostDir + ",security_model=passthrough,mount_tag=host_share"
  return virtfs
end

if __FILE__ == $0
  puts "prepare to run VM"
  o = Options.new
  puts "reading argument list..."
  o.readParams(ARGV)
  puts "parsing argument list..."
  executeQemuCmd(o)
end
